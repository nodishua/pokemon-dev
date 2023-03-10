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
	if role.unionMemberRefreshFuture: # ???????????????????????????
		return
	if nowtime_t() - role.unionMemberRefreshTime < UnionMemberRefreshTime: # ????????????
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

# ??????????????????
class UnionGet(RequestHandlerTask):
	url = r'/game/union/get'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		yield unionCallAsync(self.rpcUnion, 'MainGet', self.game.role, self.game.role.unionMemberModel)

		# ??????????????? ????????? ??????
		role = self.game.role
		if self.game.union.isFeatureOpen(UnionDefs.CrossUnionFight):
			display = ObjectCrossUnionFightGameGlobal.rankOneUnionDisplay(role.areaKey)
			if display:
				self.write({'view': display})


# ????????????
class UnionCreate(RequestHandlerTask):
	url = r'/game/union/create'

	@coroutine
	def run(self):
		# ??????????????????????????????
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Union, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		if self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionAlreadyIn)

		# vip ????????????
		if self.game.role.vip_level < ConstDefs.unionCreateNeedVip:
			raise ClientError('VIP level limit')

		# gate star????????????
		if self.game.role.gateStarSum < ConstDefs.unionCreateNeedGateStar:
			raise ClientError(ErrDefs.gateStarLessNoOpened)

		name = self.input.get('name', None)
		logo = self.input.get('logo', 1)
		joinType = self.input.get('joinType', UnionDefs.DirectJoin)

		if name is None:
			raise ClientError('name is miss')

		# ??????????????????
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
			if 'duplicate key error' in e.msg: # ???????????????
				raise ClientError(ErrDefs.unionNameDuplicated)
			else:
				raise e

		cost.cost(src='union_create')

		ObjectUnion(ret['model']['union'])
		self.game.role.syncUnion(ret['sync']['role'])
		ta.track(self.game, event='create_union')

# ????????????(??????????????????)
class UnionList(RequestHandlerTask):
	url = r'/game/union/list'

	@coroutine
	def run(self):
		# ??????????????????????????????
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

# ????????????(??????????????????)
class UnionRank(RequestHandlerTask):
	url = r'/game/union/rank'

	@coroutine
	def run(self):
		# ??????????????????????????????
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


# ??????????????????
class UnionJoin(RequestHandlerTask):
	url = r'/game/union/join'

	@coroutine
	def run(self):
		# ??????????????????????????????
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Union, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		unionID = self.input.get('unionID', None)
		if unionID is None:
			raise ClientError('unionID is miss')

		# ??????????????????
		if self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionAlreadyIn)

		# ????????????
		if unionID in self.game.role.union_join_que:
			raise ClientError(ErrDefs.unionJoinPending)

		# ????????????
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

# ??????????????????
class UnionJoinCancel(RequestHandlerTask):
	url = r'/game/union/join/cancel'

	@coroutine
	def run(self):
		unionID = self.input.get('unionID', None)
		if unionID is None:
			raise ClientError('unionID is miss')

		# ????????????
		if self.game.role.union_db_id:
			self.game.role.union_join_que = []
			raise ClientError(ErrDefs.unionAlreadyIn)

		# ???????????????
		if unionID not in self.game.role.union_join_que:
			raise ClientError(ErrDefs.unionRoleNoJoin)

		self.game.role.union_join_que.remove(unionID)
		ret = yield self.rpcUnion.call_async('JoinCancel', unionID, self.game.role.id)
		union = ObjectUnion.ObjsMap.get(unionID, None)
		if union:
			union.sync(ret['sync'].get('union', None), ret['time'])


# ??????????????????????????????
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

		# ????????????
		mail = ObjectRole.makeMailModel(roleID, UnionAccpetJoinMailID, contentArgs=(self.game.role.name,))
		MailJoinableQueue.send(mail)

		# ????????????????????????????????????????????????????????????
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.union_db_id = self.game.role.union_db_id
			game.role.union_join_que = []
			game.role.union_join_time = nowtime_t()
			# ??????????????????
			game.role.syncUnionTitle()


# ??????????????????????????????
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

		# ????????????????????????????????????????????????????????????
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			unionID = self.game.role.union_db_id
			if unionID in game.role.union_join_que:
				game.role.union_join_que.remove(unionID)


# ????????????
class UnionQuit(RequestHandlerTask):
	url = r'/game/union/quit'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# ??????????????????
		if self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionChairmanCanNotQuit)

		yield unionCallAsync(self.rpcUnion, 'Quit', self.game.role)
		self.game.role.resetUnion(nowtime_t())


# ????????????????????????
class UnionKick(RequestHandlerTask):
	url = r'/game/union/kick'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		# ??????????????????
		if roleID == self.game.role.id:
			raise ClientError(ErrDefs.unionIsMyself)

		yield unionCallAsync(self.rpcUnion, 'Kick', self.game.role, roleID)
		ObjectUnion.RoleUnionMap.pop(roleID, None)

		# ????????????????????????????????????????????????????????????
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.resetUnion(nowtime_t())


# ??????????????????????????????
class UnionChairmanPromote(RequestHandlerTask):
	url = r'/game/union/chairman/promote'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		# ?????????????????????
		if not self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionOnlyChairmanOnly)

		# ??????????????????
		if roleID == self.game.role.id:
			raise ClientError(ErrDefs.unionIsMyself)

		yield unionCallAsync(self.rpcUnion, 'ChairmanPromote', self.game.role, roleID)

		# ????????????????????????????????????????????????????????????
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.union_place = UnionDefs.ViceChairmanPlace


# ?????????????????????????????????
class UnionChairmanDemote(RequestHandlerTask):
	url = r'/game/union/chairman/demote'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		# ?????????????????????
		if not self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionOnlyChairmanOnly)

		# ??????????????????
		if roleID == self.game.role.id:
			raise ClientError(ErrDefs.unionIsMyself)

		yield unionCallAsync(self.rpcUnion, 'ChairmanDemote', self.game.role, roleID)

		# ????????????????????????????????????????????????????????????
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.union_place = UnionDefs.MemberPlace


# ????????????
class UnionChairmanSwap(RequestHandlerTask):
	url = r'/game/union/chairman/swap'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('roleID is miss')

		# ?????????????????????
		if not self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionOnlyChairmanOnly)

		# ?????????????????????
		if roleID == self.game.role.id:
			raise ClientError(ErrDefs.unionIsMyself)

		place = yield unionCallAsync(self.rpcUnion, 'ChairmanSwap', self.game.role, roleID, True)

		self.game.role.union_place = place
		# ????????????????????????????????????????????????????????????
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role.union_place = UnionDefs.ChairmanPlace


# ????????????
class UnionDestroy(RequestHandlerTask):
	url = r'/game/union/destroy'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# ?????????????????????
		if not self.game.role.isUnionChairman():
			raise ClientError(ErrDefs.unionOnlyChairmanOnly)

		# ?????????????????????
		role = self.game.role
		if self.game.union.isFeatureOpen(UnionDefs.CrossUnionFight) and ObjectCrossUnionFightGameGlobal.isCrossOpen(role.areaKey):
			if ObjectCrossUnionFightGameGlobal.isInJoinUnions(role.areaKey, role.union_db_id):
				raise ClientError("join cross_union_fight can not destroy")

		yield unionCallAsync(self.rpcUnion, 'Dissolve', self.game.role)
		union = ObjectUnion.getUnionByUnionID(self.game.role.union_db_id)
		for roleID, member in union.members.iteritems():
			# ??????????????????????????????????????????????????????
			game = ObjectGame.getByRoleID(roleID, safe=False)
			if game:
				# ??????????????????
				game.role.syncUnionTitle()
		self.game.role.resetUnion(nowtime_t())
		# ??????????????????
		ObjectUnion.ObjsMap.pop(self.game.role.union_db_id, None)

		# ??????boss??????????????????
		if ObjectYYHuoDongFactory.getYYWorldBossOpenID():
			self.rpcYYHuodong.call_async("WorldBossUnionDissolve", self.game.role.union_last_db_id)

		# ????????????????????????
		if ObjectServerGlobalRecord.isUnionQAStarted():
			rpc = ObjectServerGlobalRecord.unionqa_cross_client()
			rpc.call_async("CrossUnionQAUnionDissolve", self.game.role.areaKey, self.game.role.union_last_db_id)


# ????????????
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


# ??????????????????
class UnionIntroModify(RequestHandlerTask):
	url = r'/game/union/intro/modify'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# ?????????????????????????????????
		if not self.game.role.isUnionChairman() and not self.game.role.isUnionViceChairman():
			raise ClientError(ErrDefs.unionOnlyChairman)

		intro = self.input.get('intro', None)
		if intro is None:
			raise ClientError('intro is miss')

		# ??????????????????
		uintro = intro.decode('utf8')
		if len(uintro) > 50:
			raise ClientError(ErrDefs.unionIntroTooLong)
		if filterName(uintro):
			raise ClientError(ErrDefs.unionIntroInvalid)

		yield unionCallAsync(self.rpcUnion, 'ModifyIntro', self.game.role, intro, True)


# ??????????????????????????????
class UnionJoinModify(RequestHandlerTask):
	url = r'/game/union/join/modify'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# ??????????????????
		joinType = self.input.get('joinType', None)
		if joinType is None:
			raise ClientError('joinType is miss')
		if joinType not in (UnionDefs.RefuseJoin, UnionDefs.ApproveJoin, UnionDefs.DirectJoin):
			raise ClientError('joinType error')

		joinLevel = self.input.get('joinLevel', 0)
		if joinType != UnionDefs.RefuseJoin:
			# ??????????????????
			if joinLevel < 0 or joinLevel > ObjectRole.LevelMax:
				raise ClientError('joinLevel error')
		joinDesc = self.input.get('joinDesc', '')
		yield unionCallAsync(self.rpcUnion, 'ModifyJoinType', self.game.role, joinType, joinLevel, joinDesc)

# ????????????logo
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

# ????????????????????????
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


# ??????????????????????????????
class UnionFubenGlobalInfo(RequestHandlerTask):
	url = r'/game/union/fuben/progress'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', 0)

		info = yield self.rpcUnion.call_async('FubenUnionProgress', csvID)
		self.write({'view': info})

# ??????????????????
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

# ??????????????????
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

		# ????????????
		self.game.battle = ObjectUnionFubenBattle(self.game)
		self.game.battle.canBattle() # ?????????????????????
		buff = yield unionCallAsync(self.rpcUnion, 'FubenStart', self.game.role, csvID)
		ret = self.game.battle.begin(csvID, gateID, cards, buff)
		self.write({
			'model': ret
		})


# ????????????????????????
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
		# ????????????
		if damage > self.game.battle.maxDamage():
			logger.warning("role %d union fuben damage %d cheat can max %d", self.game.role.uid, damage, self.game.battle.maxDamage())
			raise ClientError(ErrDefs.rankCheat)

		# ????????????
		self.game.battle.result(result)
		deadly, fuben = yield unionCallAsync(self.rpcUnion, 'FubenEnd', self.game.role, self.game.battle.csvID, damage, hpMax, self.game.dailyRecord.union_fb_times + 1)
		self.game.dailyRecord.union_fb_times += 1

		cfg = csv.union.union_fuben[self.game.battle.csvID]
		eff = ObjectGainAux(self.game, cfg.challengeAward)
		deadlyTimes = self.game.monthlyRecord.union_fuben_deadly_times
		csvID = self.game.battle.csvID
		if deadly and deadlyTimes.get(csvID, 0) < ConstDefs.unionFubenDeadlyTimesLimit:  # ????????????
			eff += ObjectGainAux(self.game, cfg.killAward)
			self.game.monthlyRecord.union_fuben_deadly_times[csvID] = deadlyTimes.get(csvID, 0) + 1

		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_fuben_%d' % gateID)

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.UnionFuben, 1)
		ObjectUnionContribTask.onCount(self.game, TargetDefs.UnionFuben, 1)

		# ??????????????????
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
	# ????????????
	if game.role.union_shop_db_id:
		# ???????????? ??? ??????
		if refresh or game.unionShop.isPast():
			game.role.union_shop_db_id = None
			ObjectUnionShop.addFreeObject(game.unionShop)  # ????????????
			game.unionShop = ObjectUnionShop(game, dbc)
	# ??????????????????
	if not game.role.union_shop_db_id:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectUnionShop.makeShopItems(game)
		model = ObjectUnionShop.getFreeModel(roleID, items, last_time)  # ???????????????
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

# ????????????????????????
class UnionShopRefresh(RequestHandlerTask):
	url = r'/game/union/shop/refresh'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id or not self.game.role.union_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# ????????????????????? ?????????????????????
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

# ????????????????????????
class UnionShopBuy(RequestHandlerTask):
	url = r'/game/union/shop/buy'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1) # ???????????????????????????
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')
		if not self.game.role.union_db_id or not self.game.role.union_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		# ???????????????
		oldID = self.game.unionShop.id
		unionShop = yield getShopModel(self.game, self.dbcGame)
		if oldID != unionShop.id:
			raise ClientError(ErrDefs.shopRefresh)
		eff = self.game.unionShop.buyItem(idx, shopID, itemID, count, src='union_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_shop_buy')

# ??????????????????????????????
class UnionShopGet(RequestHandlerTask):
	url = r'/game/union/shop/get'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		yield getShopModel(self.game, self.dbcGame)


# ????????????
class UnionRename(RequestHandlerTask):
	url = r'/game/union/rename'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		name = self.input.get('name', None)
		if name is None:
			raise ClientError('name is miss')

		# ??????????????????
		uname = name.decode('utf8')
		# if len(name) > 21:
		# 	raise ClientError(ErrDefs.unionNameTooLong)
		if filterName(uname):
			raise ClientError(ErrDefs.unionNameInvalid)

		# ?????????????????????
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


# ???????????????
class UnionSendMail(RequestHandlerTask):
	url = r'/game/union/send/mail'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		role = self.game.role
		unionID = self.game.role.union_db_id

		# ?????????????????????????????????
		if not role.isUnionChairman() and not role.isUnionViceChairman():
			raise ClientError(ErrDefs.unionOnlyChairman)

		content = self.input.get('content', None)
		if content is None:
			raise ClientError('content is miss')

		# ??????????????????
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


# ??????????????????
class UnionFastJoin(RequestHandlerTask):
	url = r'/game/union/fast/join'

	@coroutine
	def run(self):
		# ??????????????????????????????
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Union, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		# ??????????????????
		if self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionAlreadyIn)

		ret = yield self.rpcUnion.call_async('FastJoin', self.game.role.unionMemberModel, self.game.role.union_last_db_id)
		self.game.role.syncUnion(ret['sync']['role'])
		self.game.union.sync(ret['sync'].get('union', None), ret['time'])


# ????????????
class UnionJoinUp(RequestHandlerTask):
	url = r'/game/union/joinup'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		# ?????????????????????????????????
		if not self.game.role.isUnionChairman() and not self.game.role.isUnionViceChairman():
			raise ClientError(ErrDefs.unionOnlyChairman)

		# ????????????????????????
		if self.game.union.join_type == UnionDefs.RefuseJoin:
			raise ClientError(ErrDefs.unionRefuseJoin)

		yield unionCallAsync(self.rpcUnion, 'SendJoinupInvite', self.game.role)

		ObjectMessageGlobal.unionJoinUpMsg(self.game)


# ??????????????????????????????
class UnionJoinRefuseAll(RequestHandlerTask):
	url = r'/game/union/join/refuse/all'

	@coroutine
	def run(self):
		if not self.game.role.union_db_id:
			raise ClientError(ErrDefs.unionNotExisted)

		yield unionCallAsync(self.rpcUnion, 'JoinRefuseAll', self.game.role)

# ?????????????????? ??????
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

		# ????????????
		role.union_contrib_tasks[csvID] = (count, UnionDefs.UnionTaskCloseFlag)
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_contrib_task')
		yield unionCallAsync(self.rpcUnion, 'AddTaskContrib', role, csvID, cfg.contrib)

		self.write({
			'view': eff.result,
		})


# ????????????
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
		# ??????VIP
		if role.vip_level < cfg.vipNeed:
			raise ClientError(ErrDefs.unionContribVIPNotEnough)
		# ????????????????????????
		cost = ObjectCostAux(self.game, cfg.cost)
		if not cost.isEnough():
			raise ClientError(ErrDefs.unionContribCostNotEnough)
		# ??????????????????
		levelCsv = csv.union.union_level[role.union_level]
		if self.game.dailyRecord.union_contrib_times >= levelCsv.ContribMax:
			raise ClientError(ErrDefs.unionContribDayMax)

		yield unionCallAsync(self.rpcUnion, 'AddContrib', role, cfg.contrib)

		# ????????????
		cost.cost(src='union_contrib')
		# ????????????????????????
		self.game.dailyRecord.union_contrib_times += 1
		# ????????????
		eff = ObjectGainAux(self.game, cfg.award)
		eff *= (1 + self.game.trainer.unionContribCoinRate)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_contrib')
		# ??????????????????
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

# ?????????????????????
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


# ???????????????????????????
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


# ???????????????????????????
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

# ???????????????????????????????????????
# ??????????????????????????????
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

		# ?????????????????????????????????????????????????????????
		# ??????????????????????????????????????????????????????????????????
		self.game.dailyRecord.union_training_speedup += times
		eff = ObjectGainAux(self.game, {'gold': ConstDefs.unionTrainingSpeedUpGold * times})
		eff.gain(src='training_speedup')
		ObjectUnionContribTask.onCount(self.game, TargetDefs.UnionSpeedup, times)

		ret = yield unionCallAsync(self.rpcUnion, 'TrainingSpeedup',  self.game.role, roleID, idx, times)

		self.write({'view': ret})


# ?????????????????????????????????
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


# ?????????????????????????????????
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

# ?????????????????????
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

# ???????????????
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
		limit = self.game.dailyRecord.redPacket_rob_count >= ConstDefs.unionRobRedpacketDailyLimit # ????????????????????????
		resp = yield unionCallAsync(self.rpcUnion, 'RedPacketRob', role, packetDBID, limit, self.game.role.union_quit_time)
		if resp['flag'] == UnionDefs.PacketFlagRole: # ????????????
			self.game.dailyRecord.redPacket_rob_count += 1
			self.game.dailyRecord.union_redPacket_robs.append((resp['type'], resp['name'], resp['val']))
		union.packet_last_time = nowtime_t()

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.UnionRobPacket, 1)

		award = {}
		ptype, val = resp['type'], resp['val']
		if ptype == UnionDefs.PacketGold:
			award['gold'] = val
			if resp['flag'] == UnionDefs.PacketFlagSys:  # ????????????
				self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketGold, 1)
		elif ptype == UnionDefs.PacketRmb:
			award['rmb'] = val
			if resp['flag'] == UnionDefs.PacketFlagSys:  # ????????????
				self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketRmb, 1)
		elif ptype == UnionDefs.PacketCoin3:
			award['coin3'] = val
			if resp['flag'] == UnionDefs.PacketFlagSys:  # ????????????
				self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketCoin3, 1)
		eff = ObjectGainAux(self.game, award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_redpacket_rob')
		ObjectMessageGlobal.unionGetRedPacketMsg(self.game, resp['flag'], resp['type'], resp['name'], val)

		self.write({
			'view': resp['infos'],
			'award': eff.result,
		})


# ?????????????????? (????????????)
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
		limit = self.game.dailyRecord.redPacket_rob_count >= ConstDefs.unionRobRedpacketDailyLimit  # ????????????????????????

		eff = ObjectGainAux(self.game, {})
		packetDBIDs = []
		redPackets = yield self.rpcUnion.call_async('RedPacketInfo', role.union_db_id)
		for dbID, redPacket in redPackets.iteritems():
			if redPacket.get("packet_flag", -1) == UnionDefs.PacketFlagSys:  # ????????????
				if role.id not in redPacket.get("members", []):  # ????????????
					packetDBIDs.append(dbID)

		for packetDBID in packetDBIDs:
			resp = yield unionCallAsync(self.rpcUnion, 'RedPacketRob', role, packetDBID, limit, self.game.role.union_quit_time)
			union.packet_last_time = nowtime_t()
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.UnionRobPacket, 1)
			award = {}
			ptype, val = resp['type'], resp['val']
			if ptype == UnionDefs.PacketGold:
				award['gold'] = val
				if resp['flag'] == UnionDefs.PacketFlagSys:  # ????????????
					self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketGold, 1)
			elif ptype == UnionDefs.PacketRmb:
				award['rmb'] = val
				if resp['flag'] == UnionDefs.PacketFlagSys:  # ????????????
					self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketRmb, 1)
			elif ptype == UnionDefs.PacketCoin3:
				award['coin3'] = val
				if resp['flag'] == UnionDefs.PacketFlagSys:  # ????????????
					self.game.achievement.onCount(AchievementDefs.UnionGetRedPacketCoin3, 1)
			eff += ObjectGainAux(self.game, award)
			ObjectMessageGlobal.unionGetRedPacketMsg(self.game, resp['flag'], resp['type'], resp['name'], val)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='union_redpacket_onekey')
		self.write({
			'view': eff.result,
		})


# ??????????????????
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

# ????????????????????????
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

# ???????????? ??????
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


# ???????????? ??????
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

# ????????????????????????
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

# ??????????????????
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
		# ????????????
		if game:
			game.role.addUnionFragDonateHistory(self.game.role, fragID)
		# ????????????
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

# ?????????????????????????????????
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
		if flag != 1: # 1????????????
			raise ClientError('can not gain')

		cfg = csv.union.union_frag_donate_award[csvID]
		eff = ObjectGainAux(self.game, cfg.award)
		self.game.role.union_frag_donate_awards[csvID] = 0 # ??????????????????
		yield effectAutoGain(eff, self.game, self.dbcGame, src='union_frag_donate_award')
		self.write({
			'view': eff.result,
		})


# ???????????? ?????????
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


# ???????????? ??????
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


# ???????????? ????????????
class UnionQAStartAnswer(RequestHandlerTask):
	url = r"/game/union/qa/answer/start"

	@coroutine
	def run(self):
		if not ObjectServerGlobalRecord.isUnionQAStarted():
			raise ClientError(ErrDefs.unionQANotOpen)

		idx = self.input.get("idx", None)  # ??????
		if not idx or type(idx) != int:
			raise ClientError("param error")

		ObjectUnionQA.startAnswer(self.game, idx)


# ???????????? ????????????
class UnionQASubmitAnswer(RequestHandlerTask):
	url = r"/game/union/qa/answer/submit"

	@coroutine
	def run(self):
		if not ObjectServerGlobalRecord.isUnionQAStarted():
			raise ClientError(ErrDefs.unionQANotOpen)

		idx = self.input.get("idx", None)  # ??????
		answer = self.input.get("answer", None)
		ret = ObjectUnionQA.submitAnswer(self.game, idx, answer)

		self.write({
			"view": {"result": ret}
		})


# ???????????? ??????/??????
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

		# ????????????????????????, ?????????????????????, ???????????????
		# ??????5??????, ???????????????, ????????????????????????????????????
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


# ???????????? ????????????
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


# ???????????? ??????
class UnionQARank(RequestHandlerTask):
	url = r"/game/union/qa/rank"

	@coroutine
	def run(self):
		ret = {}
		rpc = ObjectServerGlobalRecord.unionqa_cross_client()
		if rpc:
			ret = yield rpc.call_async('CrossUnionQARankInfo', self.game.role.areaKey, self.game.role.id, self.game.role.union_db_id)

		self.write({'view': ret})
