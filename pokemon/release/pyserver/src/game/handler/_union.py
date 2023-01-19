#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Union Handlers
'''

from framework import nowtime_t, nowtime2period, datetimefromtimestamp, nowdatetime_t, todayinclock5date2int, inclockNdate2int, int2date
from framework.csv import csv, ErrDefs, ConstDefs, L10nDefs
from framework.log import logger
from framework.word_filter import filterName
from game import ServerError, ClientError
from game.globaldata import RoleJoinUnionPendingMax, UnionChairManToMemberMailID, ShopRefreshPeriods, UnionTrainingSpeedUpMax, UnionFubenHuodongID, UnionAccpetJoinMailID, UnionMemberRefreshTime, ShopRefreshItem, UnionFragDonateMailID
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import FeatureDefs, UnionDefs, TargetDefs, AchievementDefs
from game.object.game import ObjectGame, ObjectCrossUnionFightGameGlobal
from game.object.game.role import ObjectRole
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.shop import ObjectUnionShop
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.union import ObjectUnion, ObjectUnionContribTask, ObjectUnionQA
from game.object.game.message import ObjectMessageGlobal
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.battle import ObjectUnionFubenBattle
from game.thinkingdata import ta

from game.mailqueue import MailJoinableQueue

from tornado.gen import coroutine, Return
from nsqrpc.error import CallError

@coroutine
def unionCallAsync(rpc, method, role, *args):
	ret = yield rpc.call_async(method, role.union_db_id, role.id, *args)

	exps = None
	if ret:
		time = ret.pop('time')
		model = ret.pop('model', None)
		if model:
			role.game.union.init(model['union'], time)
		sync = ret.pop('sync', None)
		if sync:
			role.game.union.sync(sync.get('union', None), time)
			role.syncUnion(sync.get('role', None))
			exps = sync.get('card_exp', None)
			role.game.cards.syncTrainingExp(exps)
		ret = ret.pop('view', None)
	if exps:
		future = refreshUnionTraining(rpc, role.game)
		if method == 'TrainingOpen':
			ret = yield future

	raise Return(ret)

def refreshUnionMember(rpc, role):
	if role.unionMemberRefreshFuture: # 上次的请求还未返回
		return
	if nowtime_t() - role.unionMemberRefreshTime < UnionMemberRefreshTime: # 时间未到
		return
	role.unionMemberRefreshFuture = rpc.call_async('RefreshUnionMember', role.unionMemberModel, role.union_db_id, role.union_join_que, role.last_time)
	role.unionMemberRefreshTime = nowtime_t()

	def done(_):
		role.unionMemberRefreshFuture = None
	role.unionMemberRefreshFuture.add_done_callback(done)

@coroutine
def refreshUnionTraining(rpc, game):
	training = None
	deployment = game.cards.deploymentForUnionTraining
	cards = deployment.getdirty('cards')
	if cards:
		cards = filter(None, cards)
		cards = [game.cards.getCard(cardID).trainingModel for cardID in cards]
		deployment.resetdirty()
		if cards:
			training = yield rpc.call_async('TrainingRefreshCards', game.role.union_db_id, game.role.id, cards)
	raise Return(training)

# 获取公会信息
class UnionGet(RequestHandlerTask):
	url = r'/game/union/get'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		yield unionCallAsync(self.rpcUnion, 'MainGet', self.game.role, self.game.role.unionMemberModel)

		# 跨服公会战 第一名 展示
		role = self.game.role
		if self.game.union.isFeatureOpen(UnionDefs.CrossUnionFight):
			display = ObjectCrossUnionFightGameGlobal.rankOneUnionDisplay(role.areaKey)
			if display:
				self.write({'view': display})


# 创建公会
class UnionCreate(RequestHandlerTask):
	url = r'/game/union/create'

	@coroutine
	def run(self):
		# 判断是否具备开启条件
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Union, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		if self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionAlreadyIn)

		# vip 是否满足
		if self.game.role.vip_level < ConstDefs.unionCreateNeedVip:
			raise ClientError('VIP level limit')

		# gate star是否满足
		if self.game.role.gateStarSum < ConstDefs.unionCreateNeedGateStar:
			raise ClientError(ErrDefs.gateStarLessNoOpened)

		name = self.input.get('name', None)
		logo = self.input.get('logo', 1)
		joinType = self.input.get('joinType', UnionDefs.DirectJoin)

		if name is None:
			raise ClientError('name is miss')

		# 名称是否合法
		uname = name.decode('utf8')
		# if len(name) > 21:
		# 	raise ClientError(ErrDefs.unionNameTooLong)
		if filterName(uname):
			raise ClientError(ErrDefs.unionNameInvalid)

		if name in ObjectUnion.NameCache:
			raise ClientError(ErrDefs.unionNameDuplicated)

		cost = ObjectCostAux(self.game, {'rmb': ConstDefs.unionCreateRMBCost})
		if not cost.isEnough():
			raise ClientError(ErrDefs.unionCreateRMBNotEnough)

		try:
			ret = yield self.rpcUnion.call_async('Create', {
				'area': self.game.role.area,
				'name': name,
				'logo': logo,
				'chairman_db_id': self.game.role.id,
				'join_type': joinType,
				'intro': L10nDefs.UnionIntro % name,
			}, self.game.role.unionMemberModel)
		except CallError as e:
			if 'duplicate key error' in e.msg: # 不允许同名
				raise ClientError(ErrDefs.unionNameDuplicated)
			else:
				raise e

		cost.cost(src='union_create')

		ObjectUnion(ret['model']['union'])
		self.game.role.syncUnion(ret['sync']['role'])
		ta.track(self.game, event='create_union')

# 公会列表(以日捐献排行)
class UnionList(RequestHandlerTask):
	url = r'/game/union/list'

	@coroutine
	def run(self):
		# 判断是否具备开启条件
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Union, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		offest = self.input.get('offest', 0)
		size = self.input.get('size', 10)

		unions = yield self.rpcUnion.call_async('List', offest, size)
		self.write({
			'view': {
				'unions': unions,
				'offest': offest,
				'size': size,
			}
		})

# 公会排行(以总捐献排行)
class UnionRank(RequestHandlerTask):
	url = r'/game/union/rank'

	@coroutine
	def run(self):
		# 判断是否具备开启条件
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Union, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		offest = self.input.get('offest', 0)
		size = self.input.get('size', 10)

		unions = yield self.rpcUnion.call_async('GetRankList', offest, size)
		self.write({
			'view': {
				'unions': unions,
				'offest': offest,
				'size': size,
			}
		})


# 申请加入公会
class UnionJoin(RequestHandlerTask):
	url = r'/game/union/join'

	@coroutine
	def run(self):
		# 判断是否具备开启条件
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Union, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		unionID = self.input.get('unionID', None)
		if unionID is None:
			raise ClientError('unionID is miss')

		# 已经加入公会
		if self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionAlreadyIn)

		# 已经申请
		if unionID in self.game.role.union_join_que:
			raise ClientError(ErrDefs.unionJoinPending)

		# 申请过多
		cancelUnionID = None
		if len(self.game.role.union_join_que) >= RoleJoinUnionPendingMax:
			cancelUnionID = self.game.role.union_join_que[0]

		ret = yield self.rpcUnion.call_async('Join', unionID, self.game.role.unionMemberModel, cancelUnionID)
		status = ret['view']
		union = ObjectUnion.ObjsMap.get(unionID, None)
		if union:
			union.sync(ret['sync'].get('union', None), ret['time'])
		self.game.role.union_join_que.append(unionID)
		self.game.role.union_join_que = self.game.role.union_join_que[-RoleJoinUnionPendingMax:]
		if status == 'joined':
			self.game.role.syncUnion(ret['sync']['role'])
		self.write({'view': {'status': status}})
		ta.track(self.game, event='apply_union',union_id=unionID)

# 取消加入公会
class UnionJoinCancel(RequestHandlerTask):
	url = r'/game/union/join/cancel'

	@coroutine
	def run(self):
		unionID = self.input.get('unionID', None)
		if unionID is None:
			raise ClientError('unionID is miss')

		# 已经入会
		if self.game.role.union_db_id:
			self.game.role.union_join_que = []
			raise ClientError(ErrDefs.unionAlreadyIn)

		# 没有申请过
		if unionID not in self.game.role.union_join_que:
			raise ClientError(ErrDefs.unionRoleNoJoin)

		self.game.role.union_join_que.remove(unionID)
		ret = yield self.rpcUnion.call_async('JoinCancel', unionID, self.game.role.id)
		union = ObjectUnion.ObjsMap.get(unionID, None)
		if union:
			union.sync(ret['sync'].get('union', None), ret['time'])


# 会长或副会长批准入会
class UnionJoinAccept(RequestHandlerTask):
	url = r'/game/union/join/accept'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		yield unionCallAsync(self.rpcUnion, 'JoinAccept', self.game.role, roleID)

		# 邮件通知
		mail = ObjectRole.makeMailModel(roleID, UnionAccpetJoinMailID, contentArgs=(self.game.role.name,))
		MailJoinableQueue.send(mail)

		# 在线玩家直接修改状态，离线玩家登录后刷新
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.union_db_id = self.game.role.union_db_id
			game.role.union_join_que = []
			game.role.union_join_time = nowtime_t()
			# 同步公会称号
			game.role.syncUnionTitle()


# 会长或副会长拒绝入会
class UnionJoinRefuse(RequestHandlerTask):
	url = r'/game/union/join/refuse'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		yield unionCallAsync(self.rpcUnion, 'JoinRefuse', self.game.role, roleID)

		# 在线玩家直接修改状态，离线玩家登录后刷新
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			unionID = self.game.role.union_db_id
			if unionID in game.role.union_join_que:
				game.role.union_join_que.remove(unionID)


# 玩家退会
class UnionQuit(RequestHandlerTask):
	url = r'/game/union/quit'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# 会长不可退会
		if self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionChairmanCanNotQuit)

		yield unionCallAsync(self.rpcUnion, 'Quit', self.game.role)
		self.game.role.resetUnion(nowtime_t())


# 会长或副会长踢人
class UnionKick(RequestHandlerTask):
	url = r'/game/union/kick'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		# 不能操作自己
		if roleID == self.game.role.id:
			raise ClientError(ErrDefs.unionIsMyself)

		yield unionCallAsync(self.rpcUnion, 'Kick', self.game.role, roleID)
		ObjectUnion.RoleUnionMap.pop(roleID, None)

		# 在线玩家直接修改状态，离线玩家登录后刷新
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.resetUnion(nowtime_t())


# 会长提拔会员为副会长
class UnionChairmanPromote(RequestHandlerTask):
	url = r'/game/union/chairman/promote'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		# 非会长不能操作
		if not self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionOnlyChairmanOnly)

		# 不能操作自己
		if roleID == self.game.role.id:
			raise ClientError(ErrDefs.unionIsMyself)

		yield unionCallAsync(self.rpcUnion, 'ChairmanPromote', self.game.role, roleID)

		# 在线玩家直接修改状态，离线玩家登录后刷新
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.union_place = UnionDefs.ViceChairmanPlace


# 会长将副会长降级为成员
class UnionChairmanDemote(RequestHandlerTask):
	url = r'/game/union/chairman/demote'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		# 非会长不能操作
		if not self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionOnlyChairmanOnly)

		# 不能操作自己
		if roleID == self.game.role.id:
			raise ClientError(ErrDefs.unionIsMyself)

		yield unionCallAsync(self.rpcUnion, 'ChairmanDemote', self.game.role, roleID)

		# 在线玩家直接修改状态，离线玩家登录后刷新
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.union_place = UnionDefs.MemberPlace


# 会长转让
class UnionChairmanSwap(RequestHandlerTask):
	url = r'/game/union/chairman/swap'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		# 非会长不能操作
		if not self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionOnlyChairmanOnly)

		# 不能转让给自己
		if roleID == self.game.role.id:
			raise ClientError(ErrDefs.unionIsMyself)

		place = yield unionCallAsync(self.rpcUnion, 'ChairmanSwap', self.game.role, roleID, True)

		self.game.role.union_place = place
		# 在线玩家直接修改状态，离线玩家登录后刷新
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.union_place = UnionDefs.ChairmanPlace


# 公会解散
class UnionDestroy(RequestHandlerTask):
	url = r'/game/union/destroy'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# 非会长不能操作
		if not self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionOnlyChairmanOnly)

		# 跨服公会战处理
		role = self.game.role
		if self.game.union.isFeatureOpen(UnionDefs.CrossUnionFight) and ObjectCrossUnionFightGameGlobal.isCrossOpen(role.areaKey):
			if ObjectCrossUnionFightGameGlobal.isInJoinUnions(role.areaKey, role.union_db_id):
				raise ClientError("join cross_union_fight can not destroy")

		yield unionCallAsync(self.rpcUnion, 'Dissolve', self.game.role)
		union = ObjectUnion.getUnionByUnionID(self.game.role.union_db_id)
		for roleID, member in union.members.iteritems():
			# 在线玩家直接同步，离线玩家登录后刷新
			game = ObjectGame.getByRoleID(roleID, safe=False)
			if game:
				# 同步公会称号
				game.role.syncUnionTitle()
		self.game.role.resetUnion(nowtime_t())
		# 清除公会缓存
		ObjectUnion.ObjsMap.pop(self.game.role.union_db_id, None)

		# 世界boss公会排行更新
		if ObjectYYHuoDongFactory.getYYWorldBossOpenID():
			self.rpcYYHuodong.call_async("WorldBossUnionDissolve", self.game.role.union_last_db_id)

		# 公会问答排行刷新
		if ObjectServerGlobalRecord.isUnionQAStarted():
			rpc = ObjectServerGlobalRecord.unionqa_cross_client()
			rpc.call_async("CrossUnionQAUnionDissolve", self.game.role.areaKey, self.game.role.union_last_db_id)


# 公会检索
class UnionFind(RequestHandlerTask):
	url = r'/game/union/find'

	@coroutine
	def run(self):
		unionID = self.input.get('unionID', None)
		if unionID is None or unionID == "":
			raise ClientError('unionID is miss')

		query = {}
		if isinstance(unionID, int):
			query['uid'] = unionID
		elif isinstance(unionID, str):
			if len(unionID) == 12:
				query['id'] = unionID
			query['name'] = unionID
			if unionID.isdigit():
				query['uid'] = int(unionID)

		if not query:
			raise ClientError('query miss')

		ret = yield self.rpcUnion.call_async('Find', query)
		if not ret:
			raise ClientError(ErrDefs.unionNotFound)
		self.write({
			'view': ret,
		})


# 公会修改公告
class UnionIntroModify(RequestHandlerTask):
	url = r'/game/union/intro/modify'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# 只有会长与副会长能操作
		if not self.game.role.isUnionChairman() and not self.game.role.isUnionViceChairman():
			raise ClientError(ErrDefs.unionOnlyChairman)

		intro = self.input.get('intro', None)
		if intro is None:
			raise ClientError('intro is miss')

		# 公告是否合法
		uintro = intro.decode('utf8')
		if len(uintro) > 50:
			raise ClientError(ErrDefs.unionIntroTooLong)
		if filterName(uintro):
			raise ClientError(ErrDefs.unionIntroInvalid)

		yield unionCallAsync(self.rpcUnion, 'ModifyIntro', self.game.role, intro, True)


# 公会修改加入等级条件
class UnionJoinModify(RequestHandlerTask):
	url = r'/game/union/join/modify'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# 公会加入条件
		joinType = self.input.get('joinType', None)
		if joinType is None:
			raise ClientError('joinType is miss')
		if joinType not in (UnionDefs.RefuseJoin, UnionDefs.ApproveJoin, UnionDefs.DirectJoin):
			raise ClientError('joinType error')

		joinLevel = self.input.get('joinLevel', 0)
		if joinType != UnionDefs.RefuseJoin:
			# 公会加入等级
			if joinLevel < 0 or joinLevel > ObjectRole.LevelMax:
				raise ClientError('joinLevel error')
		joinDesc = self.input.get('joinDesc', '')
		yield unionCallAsync(self.rpcUnion, 'ModifyJoinType', self.game.role, joinType, joinLevel, joinDesc)

# 公会修改logo
class UnionLogoModify(RequestHandlerTask):
	url = r'/game/union/logo/modify'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		logo = self.input.get('logo', None)
		if logo is None:
			raise ClientError('logo is miss')
		yield unionCallAsync(self.rpcUnion, 'ModifyLogo', self.game.role, logo)

# 领取公会副本奖励
class UnionFubenAward(RequestHandlerTask):
	url = r'/game/union/fuben/award'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.Fuben):
			raise ClientError(ErrDefs.unionFeatureNotOpen)

		month, csvIDs = yield self.rpcUnion.call_async('FubenUnionPassed', self.game.role.union_db_id)
		if csvID:
			if csvID not in csvIDs:
				raise ClientError(ErrDefs.unionFubenNoPassed)
			eff = self.game.role.getUnionFubenPassAward(month, csvID)
		else:
			eff = self.game.role.getUnionAllFubenPassAward(month, csvIDs)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_fuben')
		self.write({
			'view': eff.result,
		})


# 获取公会副本进度数据
class UnionFubenGlobalInfo(RequestHandlerTask):
	url = r'/game/union/fuben/progress'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', 0)

		info = yield self.rpcUnion.call_async('FubenUnionProgress', csvID)
		self.write({'view': info})

# 获取公会副本
class UnionFubenGet(RequestHandlerTask):
	url = r'/game/union/fuben/get'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.Fuben):
			raise ClientError(ErrDefs.unionFeatureNotOpen)

		fuben = yield unionCallAsync(self.rpcUnion, 'FubenGet', self.game.role)
		self.write({
			'model': {
				'union_fuben': fuben,
			}
		})

# 挑战公会副本
class UnionFubenStart(RequestHandlerTask):
	url = r'/game/union/fuben/start'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('csvID is miss')

		gateID = self.input.get('gateID', None)
		if gateID is None:
			raise ClientError('gateID is miss')

		if csv.union.union_fuben[csvID].gateID != gateID:
			raise ClientError('gateID error')

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.Fuben):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		cards = self.game.role.huodong_cards.get(UnionFubenHuodongID, self.game.role.battle_cards)
		if cards is None:
			raise ClientError('cards error')

		# 战斗数据
		self.game.battle = ObjectUnionFubenBattle(self.game)
		self.game.battle.canBattle() # 次数，日期判断
		buff = yield unionCallAsync(self.rpcUnion, 'FubenStart', self.game.role, csvID)
		ret = self.game.battle.begin(csvID, gateID, cards, buff)
		self.write({
			'model': ret
		})


# 结束挑战公会副本
class UnionFubenEnd(RequestHandlerTask):
	url = r'/game/union/fuben/end'

	@coroutine
	def run(self):
		battleID = self.input.get('battleID', None)
		gateID = self.input.get('gateID', None)
		result = self.input.get('result', None)
		damage = self.input.get('damage', None)
		hpMax = self.input.get('hpMax', None)

		if any([x is None for x in [battleID, gateID, result, damage, hpMax]]):
			raise ClientError('param miss')
		if gateID != self.game.battle.gateID:
			raise ClientError('gateID error')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		if not isinstance(self.game.battle, ObjectUnionFubenBattle):
			raise ServerError('fuben battle miss')

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		unionDbId = self.game.role.union_db_id
		unionName = self.game.role.union_name
		# 伤害保护
		if damage > self.game.battle.maxDamage():
			logger.warning("role %d union fuben damage %d cheat can max %d", self.game.role.uid, damage, self.game.battle.maxDamage())
			raise ClientError(ErrDefs.rankCheat)

		# 战斗结算
		self.game.battle.result(result)
		deadly, fuben = yield unionCallAsync(self.rpcUnion, 'FubenEnd', self.game.role, self.game.battle.csvID, damage, hpMax, self.game.dailyRecord.union_fb_times + 1)
		self.game.dailyRecord.union_fb_times += 1

		cfg = csv.union.union_fuben[self.game.battle.csvID]
		eff = ObjectGainAux(self.game, cfg.challengeAward)
		deadlyTimes = self.game.monthlyRecord.union_fuben_deadly_times
		csvID = self.game.battle.csvID
		if deadly and deadlyTimes.get(csvID, 0) < ConstDefs.unionFubenDeadlyTimesLimit:  # 补刀奖励
			eff += ObjectGainAux(self.game, cfg.killAward)
			self.game.monthlyRecord.union_fuben_deadly_times[csvID] = deadlyTimes.get(csvID, 0) + 1

		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_fuben_%d' % gateID)

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.UnionFuben, 1)
		ObjectUnionContribTask.onCount(self.game, TargetDefs.UnionFuben, 1)

		# 战斗结算完毕
		ret = self.game.battle.end()
		self.game.battle = None
		if eff:
			ret['view']['drop'] = eff.result
		ret['model'] = {'union_fuben': fuben, }
		ret['view']['damage'] = damage
		self.write(ret)
		if deadly:
			ta.track(self.game, event='union_fuben', gateID=gateID, union_db_id=unionDbId, union_name=unionName)

@coroutine
def getShopModel(game, dbc, refresh=False):
	# 商店存在
	if game.role.union_shop_db_id:
		# 强制刷新 或 过期
		if refresh or game.unionShop.isPast():
			game.role.union_shop_db_id = None
			ObjectUnionShop.addFreeObject(game.unionShop)  # 回收复用
			game.unionShop = ObjectUnionShop(game, dbc)
	# 重新生成商店
	if not game.role.union_shop_db_id:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectUnionShop.makeShopItems(game)
		model = ObjectUnionShop.getFreeModel(roleID, items, last_time)  # 回收站中取
		fromDB = False
		if model is None:
			ret = yield dbc.call_async('DBCreate', 'UnionShop', {
				'role_db_id': roleID,
				'items': items,
				'last_time': last_time,
			})
			model = ret['model']
			fromDB = True

		game.role.union_shop_db_id = model['id']
		game.unionShop = ObjectUnionShop(game, dbc).dbset(model, fromDB).init()

	raise Return(game.unionShop)

# 刷新公会积分商店
class UnionShopRefresh(RequestHandlerTask):
	url = r'/game/union/shop/refresh'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id or not self.game.role.union_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 是否代金券刷新 钻石刷新可不传
		itemRefresh = self.input.get('itemRefresh', None)
		if not itemRefresh:
			refreshTimes = self.game.dailyRecord.union_shop_refresh_times
			if refreshTimes >= self.game.role.shopRefreshLimit:
				raise ClientError(ErrDefs.shopRefreshUp)
			costRMB = ObjectCostCSV.getUnionShopRefreshCost(refreshTimes)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError("cost rmb not enough")
			self.game.dailyRecord.union_shop_refresh_times = refreshTimes + 1
		else:
			cost = ObjectCostAux(self.game, {ShopRefreshItem: 1})
			if not cost.isEnough():
				raise ClientError("cost item not enough")
		cost.cost(src='unionShop_refresh_cost')
		yield getShopModel(self.game, self.dbcGame, True)
		self.game.achievement.onCount(AchievementDefs.ShopRefresh, 1)

# 公会积分商店购买
class UnionShopBuy(RequestHandlerTask):
	url = r'/game/union/shop/buy'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1) # 只增对限购类型生效
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')
		if not self.game.role.union_db_id or not self.game.role.union_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# 商店过期了
		oldID = self.game.unionShop.id
		unionShop = yield getShopModel(self.game, self.dbcGame)
		if oldID != unionShop.id:
			raise ClientError(ErrDefs.shopRefresh)
		eff = self.game.unionShop.buyItem(idx, shopID, itemID, count, src='union_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_shop_buy')

# 获取公会积分商店数据
class UnionShopGet(RequestHandlerTask):
	url = r'/game/union/shop/get'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		yield getShopModel(self.game, self.dbcGame)


# 公会改名
class UnionRename(RequestHandlerTask):
	url = r'/game/union/rename'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		name = self.input.get('name', None)
		if name is None:
			raise ClientError('name is miss')

		# 名称是否合法
		uname = name.decode('utf8')
		# if len(name) > 21:
		# 	raise ClientError(ErrDefs.unionNameTooLong)
		if filterName(uname):
			raise ClientError(ErrDefs.unionNameInvalid)

		# 非会长不能操作
		if not self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionOnlyChairmanOnly)

		if name in ObjectUnion.NameCache:
			raise ClientError(ErrDefs.unionNameDuplicated)

		cost = ObjectCostAux(self.game, {'rmb': ConstDefs.unionRenameRMBCost})
		if not cost.isEnough():
			raise ClientError(ErrDefs.unionRenameRmbUp)

		yield unionCallAsync(self.rpcUnion, 'Rename', self.game.role, name)
		cost.cost(src='union_rename')

		ObjectUnion.NameCache.add(name)


# 公会发邮件
class UnionSendMail(RequestHandlerTask):
	url = r'/game/union/send/mail'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		role = self.game.role
		unionID = self.game.role.union_db_id

		# 只有会长与副会长能操作
		if not role.isUnionChairman() and not role.isUnionViceChairman():
			raise ClientError(ErrDefs.unionOnlyChairman)

		content = self.input.get('content', None)
		if content is None:
			raise ClientError('content is miss')

		# 公告是否合法
		ucontent = content.decode('utf8')
		if len(ucontent) > 50:
			raise ClientError(ErrDefs.unionMailTooLong)
		if filterName(ucontent):
			raise ClientError(ErrDefs.unionMailoInvalid)

		yield unionCallAsync(self.rpcUnion, 'SendMail', self.game.role)

		mailType = UnionChairManToMemberMailID
		cfg = csv.mail[mailType]
		from game.handler.inl_mail import sendUnionMail
		thumb = yield sendUnionMail(self.dbcGame, unionID, mailType, role.name, cfg.subject, content, None)
		resp = yield self.rpcUnion.call_async('AddMail', unionID, thumb)
		union = ObjectUnion.ObjsMap.get(unionID, None)
		if union:
			union.sync(resp['sync']['union'], resp['time'])


# 快速加入公会
class UnionFastJoin(RequestHandlerTask):
	url = r'/game/union/fast/join'

	@coroutine
	def run(self):
		# 判断是否具备开启条件
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Union, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		# 已经加入公会
		if self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionAlreadyIn)

		ret = yield self.rpcUnion.call_async('FastJoin', self.game.role.unionMemberModel, self.game.role.union_last_db_id)
		self.game.role.syncUnion(ret['sync']['role'])
		self.game.union.sync(ret['sync'].get('union', None), ret['time'])


# 公会招募
class UnionJoinUp(RequestHandlerTask):
	url = r'/game/union/joinup'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# 只有会长与副会长能操作
		if not self.game.role.isUnionChairman() and not self.game.role.isUnionViceChairman():
			raise ClientError(ErrDefs.unionOnlyChairman)

		# 公会申请类型判断
		if self.game.union.join_type == UnionDefs.RefuseJoin:
			raise ClientError(ErrDefs.unionRefuseJoin)

		yield unionCallAsync(self.rpcUnion, 'SendJoinupInvite', self.game.role)

		ObjectMessageGlobal.unionJoinUpMsg(self.game)


# 会长或副会长拒绝入会
class UnionJoinRefuseAll(RequestHandlerTask):
	url = r'/game/union/join/refuse/all'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		yield unionCallAsync(self.rpcUnion, 'JoinRefuseAll', self.game.role)

# 公会贡献任务 领取
class UnionContribTask(RequestHandlerTask):
	url = r'/game/union/contrib/task'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param is error')

		role = self.game.role
		if not role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.Contribute):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)
		cfg = csv.union.union_task[csvID]
		count, flag = role.union_contrib_tasks.get(csvID, (0, UnionDefs.UnionTaskNoneFlag))
		if flag == UnionDefs.UnionTaskCloseFlag:
			raise ClientError('The award has been got')
		if cfg.userType == UnionDefs.UnionTaskRole:
			if flag == UnionDefs.UnionTaskNoneFlag:
				raise ClientError('Task has not complete')
		else:
			count, flag = self.game.union.contrib_tasks.get(csvID, (0, 0))
			if flag == 0:
				raise ClientError('Task has not complete')

		# 获得奖励
		role.union_contrib_tasks[csvID] = (count, UnionDefs.UnionTaskCloseFlag)
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_contrib_task')
		yield unionCallAsync(self.rpcUnion, 'AddTaskContrib', role, csvID, cfg.contrib)

		self.write({
			'view': eff.result,
		})


# 公会贡献
class UnionContrib(RequestHandlerTask):
	url = r'/game/union/contrib'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		if idx is None:
			raise ClientError('param is error')

		role = self.game.role
		if not role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.Contribute):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		cfg = csv.union.contrib[idx]
		# 检查VIP
		if role.vip_level < cfg.vipNeed:
			raise ClientError(ErrDefs.unionContribVIPNotEnough)
		# 检查消耗是否足够
		cost = ObjectCostAux(self.game, cfg.cost)
		if not cost.isEnough():
			raise ClientError(ErrDefs.unionContribCostNotEnough)
		# 检查次数上限
		levelCsv = csv.union.union_level[role.union_level]
		if self.game.dailyRecord.union_contrib_times >= levelCsv.ContribMax:
			raise ClientError(ErrDefs.unionContribDayMax)

		yield unionCallAsync(self.rpcUnion, 'AddContrib', role, cfg.contrib)

		# 消耗物品
		cost.cost(src='union_contrib')
		# 增加玩家每日次数
		self.game.dailyRecord.union_contrib_times += 1
		# 增加获得
		eff = ObjectGainAux(self.game, cfg.award)
		eff *= (1 + self.game.trainer.unionContribCoinRate)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_contrib')
		# 增加相关计数
		if 'gold' in cfg.cost:
			self.game.achievement.onCount(AchievementDefs.UnionContribGold, 1)
		elif 'rmb' in cfg.cost:
			self.game.achievement.onCount(AchievementDefs.UnionContribRmb, 1)
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.UnionContrib, 1)
		ObjectUnionContribTask.onCount(self.game, TargetDefs.UnionContrib, 1)
		ObjectUnionContribTask.onCount(self.game, TargetDefs.UnionContribSum, cfg.contrib)
		self.write({
			'view': eff.result,
		})

		ta.track(self.game, event='union_donate', donate_type=idx)

# 公会训练所开启
class UnionTrainingOpen(RequestHandlerTask):
	url = r'/game/union/training/open'

	@coroutine
	def run(self):
		idx = self.input.get('idx', 0)

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		if not self.game.union.isFeatureOpen(UnionDefs.Training):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)
		if idx:
			cfg = csv.union.training[idx]
			cost = ObjectCostAux(self.game, {'rmb': cfg.costRMB})
			if not cost.isEnough():
				raise ClientError(ErrDefs.unionTrainSlotRMBNotEnough)
			cost.cost(src='union_training_open')
		training = yield unionCallAsync(self.rpcUnion, 'TrainingOpen', self.game.role, idx)
		self.write({
			'model': {
				'union_training': training,
			}
		})


# 公会训练所训练放置
class UnionTrainingStart(RequestHandlerTask):
	url = r'/game/union/training/start'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		cardID = self.input.get('cardID', None)
		if idx is None or cardID is None:
			raise ClientError('param is error')

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		if not self.game.union.isFeatureOpen(UnionDefs.Training):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		card = self.game.cards.getCard(cardID)
		if not card:
			raise ClientError('cardid error')

		training = yield unionCallAsync(self.rpcUnion, 'TrainingStart', self.game.role, idx, card.trainingModel)
		cards = [v['id'] for _, v in training['slots'].iteritems()]
		self.game.cards.deploymentForUnionTraining.deploy('cards', cards)
		self.write({
			'model': {
				'union_training': training,
			}
		})


# 公会训练所训练替换
class UnionTrainingReplace(RequestHandlerTask):
	url = r'/game/union/training/replace'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		cardID = self.input.get('cardID', None)
		if idx is None or cardID is None:
			raise ClientError('param is error')

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.Training):
			raise ClientError(ErrDefs.unionFeatureNotOpen)

		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		card = self.game.cards.getCard(cardID)
		if not card:
			raise ClientError('cardid error')

		training = yield unionCallAsync(self.rpcUnion, 'TrainingReplace', self.game.role, idx, card.trainingModel)
		cards = [v['id'] for _, v in training['slots'].iteritems()]
		self.game.cards.deploymentForUnionTraining.deploy('cards', cards)
		self.write({
			'model': {
				'union_training': training,
			}
		})


TrainingOfflineKeys = ('offline_exp', 'offline_speedup')

# 公会训练所加速（随机加速）
# 随机可以客户端来完成
class UnionTrainingSpeedUp(RequestHandlerTask):
	url = r'/game/union/training/speedup'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', "")
		idx = self.input.get('idx', 0)

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		if not self.game.union.isFeatureOpen(UnionDefs.Training):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)
		if self.game.dailyRecord.union_training_speedup >= UnionTrainingSpeedUpMax:
			raise ClientError(ErrDefs.unionTrainSpeedUpMax)

		if roleID == "" and idx == 0:
			times = UnionTrainingSpeedUpMax - self.game.dailyRecord.union_training_speedup
		else:
			times = 1

		# 不管加速成功与否，都当成功来对自己处理
		# 被加速放能加上就加上，限制好加和被加次数即可
		self.game.dailyRecord.union_training_speedup += times
		eff = ObjectGainAux(self.game, {'gold': ConstDefs.unionTrainingSpeedUpGold * times})
		eff.gain(src='training_speedup')
		ObjectUnionContribTask.onCount(self.game, TargetDefs.UnionSpeedup, times)

		ret = yield unionCallAsync(self.rpcUnion, 'TrainingSpeedup',  self.game.role, roleID, idx, times)

		self.write({'view': ret})


# 公会训练所社团营地列表
class UnionTrainingList(RequestHandlerTask):
	url = r'/game/union/training/list'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.Training):
			raise ClientError(ErrDefs.unionFeatureNotOpen)

		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		info = yield unionCallAsync(self.rpcUnion, 'TrainingList', self.game.role)
		if not info:
			raise ClientError(ErrDefs.unionCanNotHandleNonMember)
		self.write({'view': info})


# 公会训练所查看他人营地
class UnionTrainingSee(RequestHandlerTask):
	url = r'/game/union/training/see'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is error')

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		info = yield self.rpcUnion.call_async('TrainingSee', self.game.role.union_db_id, roleID)
		self.write({'view': info})

# 公会玩家发红包
class UnionRedPacketSend(RequestHandlerTask):
	url = r'/game/union/redpacket/send'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		csvID = self.input.get('csvID', None)
		if idx is None:
			raise ClientError('idx error')
		if csvID is None or csvID not in csv.union.red_packet:
			raise ClientError('csvID error')

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		info = self.game.role.union_redpackets[idx]
		if info[0] != csvID:
			raise ClientError('csvID not match')
		cfg = csv.union.red_packet[csvID]
		if (nowdatetime_t() - datetimefromtimestamp(info[1])).days > cfg.date:
			raise ClientError('expiration')

		del self.game.role.union_redpackets[idx]
		self.game.dailyRecord.redPacket_send_count += 1

		union = self.game.union
		view = yield self.rpcUnion.call_async('RedPacketSend', self.game.role.union_db_id, self.game.role.id, csvID)
		union.packet_last_time = nowtime_t()

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.UnionSendPacket, 1)
		ObjectMessageGlobal.unionSendRedPacketMsg(self.game, cfg.name)
		self.write({
			'view': view,
		})

		ta.track(self.game, event='union_bonus_push', bonus_type=cfg.type)

# 公会抢红包
class UnionRedPacketRob(RequestHandlerTask):
	url = r'/game/union/redpacket/rob'

	@coroutine
	def run(self):
		packetDBID = self.input.get('packetDBID', None)
		if packetDBID is None:
			raise ClientError('packetDBID None')

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.RedPacket):
			raise ClientError(ErrDefs.unionFeatureNotOpen)

		role = self.game.role

		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		union = self.game.union
		limit = self.game.dailyRecord.redPacket_rob_count >= ConstDefs.unionRobRedpacketDailyLimit # 玩家红包次数限制
		resp = yield unionCallAsync(self.rpcUnion, 'RedPacketRob', role, packetDBID, limit, self.game.role.union_quit_time)
		if resp['flag'] == UnionDefs.PacketFlagRole: # 玩家红包
			self.game.dailyRecord.redPacket_rob_count += 1
			self.game.dailyRecord.union_redPacket_robs.append((resp['type'], resp['name'], resp['val']))
		union.packet_last_time = nowtime_t()

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.UnionRobPacket, 1)

		award = {}
		ptype, val = resp['type'], resp['val']
		if ptype == UnionDefs.PacketGold:
			award['gold'] = val
			if resp['flag'] == UnionDefs.PacketFlagSys:  # 系统红包
				self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketGold, 1)
		elif ptype == UnionDefs.PacketRmb:
			award['rmb'] = val
			if resp['flag'] == UnionDefs.PacketFlagSys:  # 系统红包
				self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketRmb, 1)
		elif ptype == UnionDefs.PacketCoin3:
			award['coin3'] = val
			if resp['flag'] == UnionDefs.PacketFlagSys:  # 系统红包
				self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketCoin3, 1)
		eff = ObjectGainAux(self.game, award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_redpacket_rob')
		ObjectMessageGlobal.unionGetRedPacketMsg(self.game, resp['flag'], resp['type'], resp['name'], val)

		self.write({
			'view': resp['infos'],
			'award': eff.result,
		})


# 公会系统红包 (一键领取)
class UnionRedPacketOnekey(RequestHandlerTask):
	url = r'/game/union/redpacket/onekey'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.RedPacket):
			raise ClientError(ErrDefs.unionFeatureNotOpen)

		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		role = self.game.role
		union = self.game.union
		limit = self.game.dailyRecord.redPacket_rob_count >= ConstDefs.unionRobRedpacketDailyLimit  # 玩家红包次数限制

		eff = ObjectGainAux(self.game, {})
		packetDBIDs = []
		redPackets = yield self.rpcUnion.call_async('RedPacketInfo', role.union_db_id)
		for dbID, redPacket in redPackets.iteritems():
			if redPacket.get("packet_flag", -1) == UnionDefs.PacketFlagSys:  # 系统红包
				if role.id not in redPacket.get("members", []):  # 没有领过
					packetDBIDs.append(dbID)

		for packetDBID in packetDBIDs:
			resp = yield unionCallAsync(self.rpcUnion, 'RedPacketRob', role, packetDBID, limit, self.game.role.union_quit_time)
			union.packet_last_time = nowtime_t()
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.UnionRobPacket, 1)
			award = {}
			ptype, val = resp['type'], resp['val']
			if ptype == UnionDefs.PacketGold:
				award['gold'] = val
				if resp['flag'] == UnionDefs.PacketFlagSys:  # 系统红包
					self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketGold, 1)
			elif ptype == UnionDefs.PacketRmb:
				award['rmb'] = val
				if resp['flag'] == UnionDefs.PacketFlagSys:  # 系统红包
					self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketRmb, 1)
			elif ptype == UnionDefs.PacketCoin3:
				award['coin3'] = val
				if resp['flag'] == UnionDefs.PacketFlagSys:  # 系统红包
					self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketCoin3, 1)
			eff += ObjectGainAux(self.game, award)
			ObjectMessageGlobal.unionGetRedPacketMsg(self.game, resp['flag'], resp['type'], resp['name'], val)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='union_redpacket_onekey')
		self.write({
			'view': eff.result,
		})


# 获取红包信息
class UnionRedPacketInfo(RequestHandlerTask):
	url = r'/game/union/redpacket/info'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		view = yield self.rpcUnion.call_async('RedPacketInfo', self.game.role.union_db_id)
		self.write({
			'view': view,
		})

# 公会红包个别信息
class UnionRedPacketDetail(RequestHandlerTask):
	url = r'/game/union/redpacket/detail'

	@coroutine
	def run(self):
		packetDBID = self.input.get('packetDBID', None)
		if packetDBID is None:
			raise ClientError('packetDBID None')

		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		view = yield self.rpcUnion.call_async('RedPacketDetail', self.game.role.union_db_id, packetDBID)
		self.write({
			'view': view,
		})

# 修炼中心 修炼
class UnionSkill(RequestHandlerTask):
	url = r'/game/union/skill'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.UnionSkill):
			raise ClientError(ErrDefs.unionFeatureNotOpen)

		skillID = self.input.get('skillID', None)
		if skillID is None:
			raise ClientError('param miss')

		self.game.role.onUnionSkill(skillID, self.game.union.level)
		ta.track(self.game, event='union_skill_level_up', union_skill_id=skillID)


# 每日礼包 领取
class UnionDailyGift(RequestHandlerTask):
	url = r'/game/union/daily_gift'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.DailyGift):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)
		if self.game.dailyRecord.union_daily_gift_times >= 1:
			raise ClientError('dailyGift times has run out')

		eff = self.game.role.getUnionDailyGift()
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='union_daily_gift')
		self.game.dailyRecord.union_daily_gift_times += 1

		ObjectUnionContribTask.onCount(self.game, TargetDefs.UnionDailyGiftTimes, 1)

		self.write({
			'view': eff.result
		})

# 公会碎片赠予发起
class UnionFragDonateStart(RequestHandlerTask):
	url = r'/game/union/frag/donate/start'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.FragDonate):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		cardID = self.input.get('cardID', None)
		if cardID is None:
			raise ClientError('param miss')
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('cardID error')
		if self.game.dailyRecord.union_frag_donate_start_times > 0:
			raise ClientError('times not enough')

		fragID = csv.cards[card.card_id].fragID
		if csv.fragments[fragID].donateType == 0:
			raise ClientError('type error')
		quality = csv.fragments[fragID].quality
		cfg = csv.union.union_frag_donate[quality]
		self.game.dailyRecord.union_frag_donate_start_times += 1
		success = yield unionCallAsync(self.rpcUnion, 'FragDonateStart', self.game.role, fragID, cfg.totalmax)
		if not success:
			raise ClientError(ErrDefs.unionFragDonateStartNotSuccess)

		ta.track(self.game, event='fragment_wishing', fragment_id=fragID)

# 公会碎片赠予
class UnionFragDonate(RequestHandlerTask):
	url = r'/game/union/frag/donate'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.FragDonate):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		roleID = self.input.get('roleID', None)
		fragID = self.input.get('fragID', None)
		if roleID is None or fragID is None:
			raise ClientError('param miss')
		if self.game.dailyRecord.union_frag_donate_times >= ConstDefs.unionFragDonateTimes:
			raise ClientError('times not enough')

		cost = ObjectCostAux(self.game, {fragID: 1})
		if not cost.isEnough():
			raise ClientError('cost not enough')
		success = yield unionCallAsync(self.rpcUnion, 'FragDonate', self.game.role, roleID, fragID, ConstDefs.unionFragDonateSingleMaxTimes)
		if not success:
			raise ClientError(ErrDefs.unionFragDonateNotSuccess)
		cost.cost(src='union_frag_donate')

		quality = csv.fragments[fragID].quality
		cfg = csv.union.union_frag_donate[quality]
		self.game.dailyRecord.union_frag_donate_times += 1
		self.game.role.union_frag_donate_point += cfg.point
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_frag_donate')

		mail = ObjectRole.makeMailModel(roleID, UnionFragDonateMailID, attachs={fragID: 1}, contentArgs=self.game.role.name)
		MailJoinableQueue.send(mail)

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.UnionFragDonate, 1)
		ObjectUnionContribTask.onCount(self.game, TargetDefs.UnionFragDonate, 1)
		self.game.achievement.onCount(AchievementDefs.UnionFragDonate, 1)

		game = ObjectGame.getByRoleID(roleID, safe=False)
		# 玩家在线
		if game:
			game.role.addUnionFragDonateHistory(self.game.role, fragID)
		# 玩家离线
		else:
			historysData = yield self.dbcGame.call_async('DBMultipleReadKeys', 'Role', [roleID], ['union_frag_donate_historys'])
			if not historysData['ret']:
				raise ServerError('db read union_frag_donate_historys error')
			historysData = historysData['models'][0]['union_frag_donate_historys']
			historysData = ObjectRole.addUnionFragDonateHistoryInMem(historysData, self.game.role, fragID)
			ret = yield self.dbcGame.call_async('DBUpdate', 'Role', roleID, {'union_frag_donate_historys': historysData}, False)
			if not ret['ret']:
				raise ServerError('db update union_frag_donate_historys error\n%s' % str(ret))

		self.write({
			'view': eff.result,
		})

		from game.thinkingdata import ta
		ta.track(self.game, event='fragment_donate', fragment_id=fragID)

# 公会碎片赠予热心人奖励
class UnionFragDonateAward(RequestHandlerTask):
	url = r'/game/union/frag/donate/award'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.FragDonate):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param miss')

		flag = self.game.role.union_frag_donate_awards.get(csvID, None)
		if flag != 1: # 1为可领取
			raise ClientError('can not gain')

		cfg = csv.union.union_frag_donate_award[csvID]
		eff = ObjectGainAux(self.game, cfg.award)
		self.game.role.union_frag_donate_awards[csvID] = 0 # 标记为已领取
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_frag_donate_award')
		self.write({
			'view': eff.result,
		})


# 公会问答 主界面
class UnionQAMain(RequestHandlerTask):
	url = r"/game/union/qa/main"

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not self.game.union.isFeatureOpen(UnionDefs.UnionQA):
			raise ClientError(ErrDefs.unionFeatureNotOpen)
		if self.game.role.inUnionQuitCD():
			raise ClientError(ErrDefs.unionNotInTime)

		rpc = ObjectServerGlobalRecord.unionqa_cross_client()
		if rpc:
			ret = yield rpc.call_async("CrossUnionQAMain", self.game.role.areaKey, self.game.role.id, self.game.role.union_db_id)
		else:
			ret = {}

		self.write({
			"view": ret,
		})


# 公会问答 准备
class UnionQAPerpare(RequestHandlerTask):
	url = r"/game/union/qa/prepare"

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)
		if not ObjectServerGlobalRecord.isUnionQAStarted():
			raise ClientError(ErrDefs.unionQANotOpen)

		if self.game.dailyRecord.union_qa_times >= self.game.dailyRecord.union_qa_buy_times + ConstDefs.unionQATimes:
			raise ClientError(ErrDefs.unionQATimesLimit)
		questions = ObjectUnionQA.prepare(self.game)
		self.game.dailyRecord.union_qa_times += 1
		self.game.dailyRecord.union_qa_union_db_id = self.game.role.union_db_id

		self.write({
			"view": {"questions": questions}
		})


# 公会问答 开始答题
class UnionQAStartAnswer(RequestHandlerTask):
	url = r"/game/union/qa/answer/start"

	@coroutine
	def run(self):
		if not ObjectServerGlobalRecord.isUnionQAStarted():
			raise ClientError(ErrDefs.unionQANotOpen)

		idx = self.input.get("idx", None)  # 题号
		if not idx or type(idx) != int:
			raise ClientError("param error")

		ObjectUnionQA.startAnswer(self.game, idx)


# 公会问答 提交答案
class UnionQASubmitAnswer(RequestHandlerTask):
	url = r"/game/union/qa/answer/submit"

	@coroutine
	def run(self):
		if not ObjectServerGlobalRecord.isUnionQAStarted():
			raise ClientError(ErrDefs.unionQANotOpen)

		idx = self.input.get("idx", None)  # 题号
		answer = self.input.get("answer", None)
		ret = ObjectUnionQA.submitAnswer(self.game, idx, answer)

		self.write({
			"view": {"result": ret}
		})


# 公会问答 结束/退出
class UnionQASettle(RequestHandlerTask):
	url = r"/game/union/qa/settle"

	@coroutine
	def run(self):
		eff = ObjectGainAux(self.game, {})
		for idx, answer in self.game.role.union_qa_answers.iteritems():
			if answer:
				cfg = csv.union_qa.qa_base[idx]
				typeCfg = csv.union_qa.qa_type[cfg.typeSeqID]
				award = ObjectGainAux(self.game, typeCfg.award)
				eff += award
		if eff:
			effectAutoGain(eff, self.game, self.dbcGame, src="union_qa")

		view = {"result": eff.result}

		# 结算前开始的答题, 仅获得结算奖励, 不更新积分
		# 周日5点前, 开始的答题, 结算时积分计入周日的分数
		if self.game.role.union_qa_score > self.game.dailyRecord.union_qa_top_score and ObjectServerGlobalRecord.isUnionQAStarted():
			rpc = ObjectServerGlobalRecord.unionqa_cross_client()
			data = ObjectUnionQA.makeUnionQAModel(self.game)
			data["score"] = self.game.role.union_qa_score
			data["weekday"] = int2date(todayinclock5date2int()).isoweekday()
			view["ranks"] = yield rpc.call_async("CrossUnionQAUpdate", self.game.role.areaKey, data)
			self.game.dailyRecord.union_qa_top_score = data["score"]

		ObjectUnionQA.resetQAGameData(self.game)

		self.write({
			"view": view
		})


# 公会问答 购买次数
class UnionQABuy(RequestHandlerTask):
	url = r"/game/union/qa/buy"

	@coroutine
	def run(self):
		if not ObjectServerGlobalRecord.isUnionQAStarted():
			raise ClientError(ErrDefs.unionQANotOpen)

		if self.game.dailyRecord.union_qa_buy_times >= ConstDefs.unionQABuyTimes:
			raise ClientError("buy time max")

		costRMB = ObjectCostCSV.getUnionQABuyCost(self.game.dailyRecord.union_qa_buy_times)
		cost = ObjectCostAux(self.game, {"rmb": costRMB})
		if not cost.isEnough():
			raise ClientError("rmb not enough")
		cost.cost(src="union_qa_buy_times")

		self.game.dailyRecord.union_qa_buy_times += 1


# 公会问答 排行
class UnionQARank(RequestHandlerTask):
	url = r"/game/union/qa/rank"

	@coroutine
	def run(self):
		ret = {}
		rpc = ObjectServerGlobalRecord.unionqa_cross_client()
		if rpc:
			ret = yield rpc.call_async('CrossUnionQARankInfo', self.game.role.areaKey, self.game.role.id, self.game.role.union_db_id)

		self.write({'view': ret})
