#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Clone Monster Handlers
'''

from framework import nowtime_t, nowdatetime_t, date2int, OneDay, datetimefromtimestamp
from framework.csv import ErrDefs, L10nDefs, csv, ConstDefs
from framework.helper import getL10nCsvValue

from game import ClientError
from game.mailqueue import ObjectMailEffect
from game.globaldata import CloneInviteCDTime, CloneRoomFinishedAwardMailID, CloneRoomBeKickedMailID, CloneRoomNotifyVoteMailID, CloneRoomLeaderWaringMailID, CloneRoomNewLeaderMailID
from game.mailqueue import MailJoinableQueue
from game.handler.inl import effectAutoGain
from game.handler.task import RequestHandlerTask
from game.object import FeatureDefs, SceneDefs, TargetDefs
from game.object.game.gain import ObjectCostAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.message import ObjectMessageGlobal
from game.object.game.lottery import ObjectDrawRandomItem
from game.object.game.gain import ObjectGainAux
from game.object.game.role import ObjectRole
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.society import ObjectSocietyGlobal
from game.object.game.card import CardSlim, ObjectCard
from game.thinkingdata import ta

from tornado.gen import coroutine


def joniRoomModel(game):
	card = game.cards.getMaxFightPointCard()
	cardD = card.battleModel(False, False, SceneDefs.Clone)
	cardD2 = None
	if card.twinFlag:
		from game.object.game.card import card2twin
		twin = card2twin(card)
		cardD2 = twin.battleModel(False, False, SceneDefs.Clone)
	return {
		"id": game.role.id,
		"name": game.role.name,
		"logo": game.role.logo,
		"vip": game.role.vip_level_display,
		"frame": game.role.frame,
		"level": game.role.level,
		"card": cardD,
		'card2': cardD2,
		"markIDs": list(game.pokedex.getAllMarkIDs())
	}

def boradcastRoom(self, room):
	if not room:
		return
	toRoles = []
	for place in room['places'].itervalues():
		if place['id'] == self.game.role.id:
			continue
		toRoles.append(place['id'])
	self.pushToRole('/game/push', {
		'model': {'clone_room': room},
	}, toRoles)


def updateRoleCLoneRoomInfo(role, room, clearCreateTime=True):
	inRoom = False
	if room:
		for place in room['places'].itervalues():
			if place['id'] == role.id:
				role.clone_deploy_card_db_id = place['card']['id']
				inRoom = True
				break

	if inRoom:
		role.clone_room_db_id = room['id']
		role.clone_room_create_time = room['create_time']
	else:
		role.clone_room_db_id = None
		role.clone_deploy_card_db_id = None

		# 创建时间只会这里清理，用于处理第一次进入提示上次被踢出的情况
		# 被踢出的次数也只会在这个接口内发生变化
		if clearCreateTime:
			role.clone_room_create_time = 0

# 获取元素挑战数据
class CloneGet(RequestHandlerTask):
	url = r'/game/clone/get'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Clone, self.game):
			raise ClientError(ErrDefs.cloneLevelNotEnough)

		ret = yield self.rpcClone.call_async("CloneGet", self.game.role.id)

		resp = 	{'view': {
			'beKicked': False,
			'nature': ret['nature']
		}}

		if ret['room']:
			resp['model'] = {
				'clone_room': ret['room']
			}

		else:
			now = nowdatetime_t()
			nowDate = date2int(now.date() if now.hour >= 12 else (now - OneDay).date())
			oldCreateDate = 0

			if self.game.role.clone_room_create_time:
				oldCreateDatetiime = datetimefromtimestamp(float(self.game.role.clone_room_create_time))
				oldCreateDate = date2int(oldCreateDatetiime.date() if oldCreateDatetiime.hour >= 12 else (oldCreateDatetiime - OneDay).date())

			# 过了刷新点
			if self.game.role.clone_last_date != nowDate:
				self.game.role.clone_daily_be_kicked_num = 0
				self.game.role.clone_last_date = nowDate

			# 没过刷新时间点，原来的房间找不到了，说明是被踢了
			elif oldCreateDate and oldCreateDate == nowDate:
				self.game.role.clone_daily_be_kicked_num += 1
				resp['view']['beKicked'] = True

		updateRoleCLoneRoomInfo(self.game.role, ret['room'])

		self.write(resp)


# 快速加入房间
class CloneFastJoinRoom(RequestHandlerTask):
	url = r'/game/clone/room/join/fast'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Clone, self.game):
			raise ClientError(ErrDefs.cloneLevelNotEnough)

		if self.game.role.clone_daily_be_kicked_num >= ConstDefs.cloneDailyBeKickedMax:
			raise ClientError("be kicked too much")

		natureID = self.input.get('natureID', None)
		if natureID is None:
			raise ClientError('natureID is miss')

		placeModel = joniRoomModel(self.game)
		room = yield self.rpcClone.call_async("FastRoom", natureID, placeModel)
		updateRoleCLoneRoomInfo(self.game.role, room)

		boradcastRoom(self, room)
		self.write({
			"model": {
				"clone_room": room
			}
		})


# 加入房间
class CloneJoinRoom(RequestHandlerTask):
	url = r'/game/clone/room/join'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Clone, self.game):
			raise ClientError(ErrDefs.cloneLevelNotEnough)

		if self.game.role.clone_daily_be_kicked_num >= ConstDefs.cloneDailyBeKickedMax:
			raise ClientError("be kicked too much")

		roomID = self.input.get('roomID', None)
		if roomID is None:
			raise ClientError('roomID is miss')

		placeModel = joniRoomModel(self.game)
		room = yield self.rpcClone.call_async("JoinRoom", roomID, placeModel)
		updateRoleCLoneRoomInfo(self.game.role, room)

		boradcastRoom(self, room)
		self.write({
			"model": {
				"clone_room": room
			}
		})

# 退出房间
class CloneQuitRoom(RequestHandlerTask):
	url = r'/game/clone/room/quit'

	@coroutine
	def run(self):
		if self.game.role.clone_room_db_id:
			room = yield self.rpcClone.call_async("QuitRoom", self.game.role.id)
			updateRoleCLoneRoomInfo(self.game.role, room)
			boradcastRoom(self, room)

# 房主踢人
class CloneKickRoom(RequestHandlerTask):
	url = r'/game/clone/room/kick'

	@coroutine
	def run(self):
		if not self.game.role.clone_room_db_id:
			raise ClientError('cloneRoomOutDate')

		roleID = self.input.get('roleID', None)
		if roleID is None:
			raise ClientError('param miss')

		room = yield self.rpcClone.call_async("KickRoom", self.game.role.id, roleID)
		mail = ObjectRole.makeMailModel(roleID, CloneRoomBeKickedMailID)
		MailJoinableQueue.send(mail)

		boradcastRoom(self, room)
		self.write({
			'model': {
				"clone_room": room
			}
		})

class CloneVoteRoom(RequestHandlerTask):
	url = r'/game/clone/room/vote'

	@coroutine
	def run(self):
		if not self.game.role.clone_room_db_id:
			raise ClientError('cloneRoomOutDate')

		vote = self.input.get('vote', None)
		if vote is None:
			raise ClientError('param miss')
		if vote not in (-1, 1):
			raise ClientError('param error')

		resp = yield self.rpcClone.call_async('VoteRoom', self.game.role.id, vote)

		if resp['first']:
			for place in resp['room']['places'].itervalues():
				# 房主另外邮件
				if place['id'] == resp['room']['leader']:
					mail = ObjectRole.makeMailModel(place['id'], CloneRoomLeaderWaringMailID)
					MailJoinableQueue.send(mail)
					continue

				# 过滤不符合条件
				if place['play'] <= 0:
					continue

				# 过滤自己
				if place['id'] == self.game.role.id:
					continue

				mail = ObjectRole.makeMailModel(place['id'], CloneRoomNotifyVoteMailID)
				MailJoinableQueue.send(mail)

		if resp['oldLeader']:
			mail = ObjectRole.makeMailModel(resp['oldLeader'], CloneRoomBeKickedMailID)
			MailJoinableQueue.send(mail)

			mail = ObjectRole.makeMailModel(resp['room']['leader'], CloneRoomNewLeaderMailID)
			MailJoinableQueue.send(mail)

		boradcastRoom(self, resp['room'])
		self.write({
			'model': {
				"clone_room": resp['room']
			},
			'view': {
				'result': resp['result']
			}
		})


# 创建房间
class CloneCreateRoom(RequestHandlerTask):
	url = r'/game/clone/room/create'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Clone, self.game):
			raise ClientError(ErrDefs.cloneLevelNotEnough)

		if self.game.role.clone_daily_be_kicked_num >= ConstDefs.cloneDailyBeKickedMax:
			raise ClientError("be kicked too much")

		natureID = self.input.get('natureID', None)
		if natureID is None:
			raise ClientError('natureID is miss')

		placeModel = joniRoomModel(self.game)
		room = yield self.rpcClone.call_async("CreateRoom", natureID, placeModel)
		updateRoleCLoneRoomInfo(self.game.role, room)

		boradcastRoom(self, room)
		self.write({
			'model': {
				'clone_room': room
			}
		})


# 是否快速加入房间
class CloneRoomEnableFast(RequestHandlerTask):
	url = r'/game/clone/room/join/fast/enable'

	@coroutine
	def run(self):
		enable = self.input.get('enable', True)
		room = yield self.rpcClone.call_async("FastEnable", self.game.role.id, enable)
		boradcastRoom(self, room)
		self.write({
			'model': {
				'clone_room': room
			}
		})

# 开始战斗
class CloneBattleStart(RequestHandlerTask):
	url = r'/game/clone/battle/start'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('csvID is miss')

		battleCardIDs = self.input.get('battleCardIDs', None)
		if battleCardIDs is None:
			raise ClientError('battleCardIDs is error')

		battlePos = [""] * 6
		if isinstance(battleCardIDs, list):
			for i, v in enumerate(battleCardIDs):
				battlePos[i] = v
		else:
			for k, v in battleCardIDs.iteritems():
				battlePos[int(k) -1]= v

		role = {
			"id": self.game.role.id,
			"name": self.game.role.name,
			"logo": self.game.role.logo,
			"level": self.game.role.level,
			"frame": self.game.role.frame,
			"figure": self.game.role.figure
		}

		resp = yield self.rpcClone.call_async("BattleStart", role, csvID, battlePos)
		self.game.role.cloneSelectMonster = csvID
		self.game.role.cloneBoxDrawNum = 0

		self.write({
			"model": {
				"clone_room": resp["room"],
				"clone_battle": resp["record"]
			}
		})

# 结束战斗
class CloneBattleEnd(RequestHandlerTask):
	url = r'/game/clone/battle/end'

	@coroutine
	def run(self):
		result = self.input.get('result', None)
		if result is None:
			raise ClientError('result is error')

		resp = yield self.rpcClone.call_async("BattleEnd", self.game.role.id, result)
		if resp:
			box = resp['box']
			ret = {}
			if box['fragNum'] > 0:
				ret[box['fragID']] = box['fragNum']

			for libID in box['dropLib']:
				lib = ObjectDrawRandomItem.getObject(libID)
				if lib:
					itemTs = lib.getRandomItem(self.game)
					ret = ObjectDrawRandomItem.packToDict(itemTs, ret)

			eff = ObjectGainAux(self.game, ret)
			yield effectAutoGain(eff, self.game, self.dbcGame, src='clone_win')

			for mail in resp['mails']:
				mailEff = ObjectMailEffect(ObjectRole.makeMailModel(
					mail['role_db_id'],
					CloneRoomFinishedAwardMailID,
					contentArgs=mail['count'],
					attachs=mail['award']
				))
				yield effectAutoGain(mailEff, self.game, self.dbcGame, src='clone_finished')

			# 重置为12点，但通用任务和日常任务重置为5点
			self.game.dailyRecord.clone_times += 1
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.CloneBattleTimes, 1)

			roleIDs = {info['id'] for info in resp['room']['places'].values()}
			if self.game.role.reunionBindRole in roleIDs:
				from game.handler._yyhuodong import getReunion
				reunion = yield getReunion(self.dbcGame, self.game.role.reunion['info']['role_id'])
				ObjectYYHuoDongFactory.refreshReunionRecord(self.game, reunion, TargetDefs.CooperateClone, 1)

			boradcastRoom(self, resp['room'])

			self.write({
				"model": {
					"clone_room": resp["room"]
				},
				"view": {
					"result": result,
					"finished": resp['room']['finish_num'],
					"freeBox":eff.result
				}
			})
		else:
			self.write({"view": {"result": result}})

		ta.track(self.game, event='clone',battle_result=result)

# 部署元素挑战上阵卡牌
class CloneDeployCard(RequestHandlerTask):
	url = r'/game/clone/battle/deploy'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		if cardID is None:
			raise ClientError('cardID is miss')

		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError(ErrDefs.cloneCardNotExisted)
		cardD = card.battleModel(False, False, SceneDefs.Clone)
		cardD2 = None
		if card.twinFlag:
			from game.object.game.card import card2twin
			twin = card2twin(card)
			cardD2 = twin.battleModel(False, False, SceneDefs.Clone)

		room = yield self.rpcClone.call_async(
			"DeployCard",
			self.game.role.id,
			cardD,
			cardD2,
		)
		self.game.role.clone_deploy_card_db_id = cardID
		boradcastRoom(self, room)
		self.write({
			'model': {
				"clone_room": room
			}
		})

# 挑战胜利宝箱
class CloneDrawBox(RequestHandlerTask):
	url = r'/game/clone/box/draw'

	@coroutine
	def run(self):
		costSeq = csv.clone.draw_box_cost[csv.unit[csv.cards[csv.clone.monster[self.game.role.cloneSelectMonster].cardID].unitID].rarity].seqParam
		if self.game.role.cloneBoxDrawNum >= len(costSeq):
			raise ClientError(ErrDefs.drawBoxNotEnough)

		cost = ObjectCostAux(self.game, {
			'rmb': costSeq[self.game.role.cloneBoxDrawNum]
		})
		if not cost.isEnough():
			raise ClientError(ErrDefs.cloneDrawBoxRMBNotEnough)
		cost.cost(src='clone_box_draw')

		box = yield self.rpcClone.call_async("BoxDraw", self.game.role.id)

		ret = {}
		if box['fragNum'] > 0:
			ret[box['fragID']] = box['fragNum']

		for libID in box['dropLib']:
			lib = ObjectDrawRandomItem.getObject(libID)
			if lib:
				itemTs = lib.getRandomItem(self.game)
				ret = ObjectDrawRandomItem.packToDict(itemTs, ret)

		eff = ObjectGainAux(self.game, ret)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='clone_win')
		self.game.role.cloneBoxDrawNum += 1

		self.write({'view': {'result': eff.result}, 'drawNum': self.game.role.cloneBoxDrawNum})

# 元素挑战挑战邀请
class CloneInvite(RequestHandlerTask):
	url = r'/game/clone/invite'

	@coroutine
	def run(self):
		msgType = self.input.get('msgType', None)
		if msgType is None:
			raise ClientError('msgType is miss')

		resp = yield self.rpcClone.call_async("CloneGet", self.game.role.id)
		room = resp['room']
		if not room:
			raise ClientError(ErrDefs.cloneRoomOutDate)

		if room['leader'] != self.game.role.id:
			raise ClientError(ErrDefs.cloneNeedLeader)

		msgFormat = (
			self.game.role.name,  # 玩家名字
			getL10nCsvValue(csv.clone.nature[room['nature_id']], 'name'), # 元素名
			L10nDefs.pauseMark.join([getL10nCsvValue(csv.cards[csv.clone.monster[i].cardID], 'name') for i in room ['monsters']])
		)

		now = nowtime_t()
		if msgType == 'world':
			if now - self.game.role.clone_world_invite_last_time < CloneInviteCDTime:
				raise ClientError(ErrDefs.cloneInviteInCD)
			self.game.role.clone_world_invite_last_time = now
			ObjectMessageGlobal.worldCloneInviteMsg(self.game, msgFormat, room['id'], room['nature_id'])

		elif msgType == 'union':
			if self.game.union is None:
				raise ClientError(ErrDefs.chatNoUnion)

			if now - self.game.role.clone_union_invite_last_time < CloneInviteCDTime:
				raise ClientError(ErrDefs.cloneInviteInCD)
			self.game.role.clone_union_invite_last_time = now
			ObjectMessageGlobal.unionCloneInviteMsg(self.game, msgFormat, room['id'], room['nature_id'])

		elif msgType == 'friend':
			friend = self.input.get('friend', None)

			if friend is None:
				raise ClientError('friend is miss')
			msg = ObjectMessageGlobal.friendCloneInviteMsg(self.game, friend, msgFormat, room['id'], room['nature_id'])
			self.pushToRole('/game/push', {
				'msg': {'msgs': [msg]},
			}, friend['id'])

# 元素挑战邀请时的在线好友
class CloneFriendOnlineList(RequestHandlerTask):
	url = r'/game/clone/friend/online/list'

	@coroutine
	def run(self):
		allOnlineFriends = ObjectSocietyGlobal.getOnlineFriends(self.game)
		hasBattleFriends = yield self.rpcClone.call_async('HasBattleFriends', [
			friend['id'] for friend in allOnlineFriends
		])

		openLevel = ObjectFeatureUnlockCSV.getOpenLevel(FeatureDefs.Clone)

		ret = []
		for friend in allOnlineFriends:
			if friend['id'] in hasBattleFriends:
				continue
			if friend['level'] < openLevel:
				continue
			ret.append(friend)

		self.write({'view': {
			'roles': ret,
			'size': len(ret),
		}})

# 进入布阵
class CLoneEnterDeploy(RequestHandlerTask):
	url = r'/game/clone/battle/deploy/enter'

	@coroutine
	def run(self):
		robots = yield self.rpcClone.call_async('EnterDeploy', self.game.role.id)
		robots = {} if robots is None else robots

		for k, v in robots.iteritems():
			card = CardSlim(v)
			v['fighting_point'] = ObjectCard.calcFightingPoint(card, v['attrs'])
			robots[k] = v

		self.write({
			'robots': robots
		})

# 是否需要机器人
class CloneSetRobot(RequestHandlerTask):
	url = r'/game/clone/room/robot/enable'

	@coroutine
	def run(self):
		enable = self.input.get('enable', True)
		room = yield self.rpcClone.call_async("RobotEnable", self.game.role.id, enable)
		boradcastRoom(self, room)
		self.write({
			'model': {
				'clone_room': room
			}
		})
