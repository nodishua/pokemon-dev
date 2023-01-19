#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.csv import csv, ErrDefs
from framework.log import logger

from game import ClientError
from game.globaldata import CrossNormalBraveChallengeRanking, NormalBraveChallengePlayID
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import BraveChallengeDefs, FeatureDefs, TargetDefs
from game.object.game import ObjectFeatureUnlockCSV
from game.object.game.yyhuodong import ObjectYYBraveChallenge, ObjectYYHuoDongFactory
from tornado.gen import coroutine
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.servrecord import ObjectServerGlobalRecord


# 检查是否开放
def checkOpen(game):
	if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.NormalBraveChallenge, game):
		return False

	if game.role.normal_brave_challenge_record_db_id is None:
		return False

	if not ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', None):
		return False

	return True


# 勇者挑战 主界面
class NormalBraveChallengeMain(RequestHandlerTask):
	url = r"/game/brave_challenge/main"

	@coroutine
	def run(self):
		game = self.game
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.NormalBraveChallenge, game):
			raise ClientError(ErrDefs.huodongNoOpen)

		role = self.game.role
		if role.normal_brave_challenge_record_db_id is None:
			record = yield self.rpcYYHuodong.call_async("BraveChallengeCreateRecord", role.id, NormalBraveChallengePlayID)
			role.normal_brave_challenge_record_db_id = record["id"]
		else:
			record = yield self.rpcYYHuodong.call_async("BraveChallengeGetRecord", role.normal_brave_challenge_record_db_id, role.id, NormalBraveChallengePlayID, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))

		ObjectYYBraveChallenge.refreshRecord(NormalBraveChallengePlayID, self.game)

		record["baseCfgID"] = ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('baseCfgID', 0)
		self.write({"model": {"brave_challenge": record}})  # 普通勇者与周年庆勇者的main两者返回一致


# 勇者挑战 开始准备
class BraveChallengePrepareStart(RequestHandlerTask):
	url = r"/game/brave_challenge/prepare/start"

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)
		role = self.game.role

		if ObjectYYBraveChallenge.isTimesLimit(self.game, NormalBraveChallengePlayID):
			raise ClientError("daily brave challenge times limit up")

		data = yield self.rpcYYHuodong.call_async("BraveChallengeStartPrepare", role.normal_brave_challenge_record_db_id, role.id, NormalBraveChallengePlayID, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))
		self.write({"view": data})


# 勇者挑战 结束准备
class BraveChallengePrepareEnd(RequestHandlerTask):
	url = r"/game/brave_challenge/prepare/end"

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)
		role = self.game.role

		cards = self.input.get("cards", None)
		if not cards or len(cards) != 3:
			raise ClientError("cards num should be 3")

		cards = sorted(cards)
		record = yield self.rpcYYHuodong.call_async("BraveChallengeEndPrepare", role.normal_brave_challenge_record_db_id, role.id, NormalBraveChallengePlayID, cards, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))
		if not record.get('game', {}).get('new_badges', []):
			flag, weight = ObjectYYBraveChallenge.isTodayFirst(self.game, NormalBraveChallengePlayID)
			if flag:
				record = yield self.rpcYYHuodong.call_async("BraveChallengeRandomBadge", role.normal_brave_challenge_record_db_id, role.id, NormalBraveChallengePlayID, weight, -1, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))

		ObjectYYBraveChallenge.addTimes(self.game, NormalBraveChallengePlayID)
		self.write({"model": {"brave_challenge": record}})


# 勇者挑战 布阵
class BraveChallengeDelpoy(RequestHandlerTask):
	url = r"/game/brave_challenge/deploy"

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)
		role = self.game.role

		cards = self.input.get("cards", None)
		if cards:
			cards = ObjectYYBraveChallenge.transform2list(cards)
		else:
			raise ClientError("cards miss")

		record = yield self.rpcYYHuodong.call_async("BraveChallengeDeploy", role.normal_brave_challenge_record_db_id, role.id, NormalBraveChallengePlayID, cards, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))
		self.write({"model": {"brave_challenge": record}})


# 勇者挑战 开始战斗
class BraveChallengeBattleStart(RequestHandlerTask):
	url = r"/game/brave_challenge/battle/start"

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)
		role = self.game.role

		cards = self.input.get("cards", None)  # csvIDs
		floorID = self.input.get("floorID", 0)
		monsterID = self.input.get("monsterID", 0)

		if cards:
			cards = ObjectYYBraveChallenge.transform2list(cards)
			yield self.rpcYYHuodong.call_async("BraveChallengeDeploy", role.normal_brave_challenge_record_db_id, role.id, NormalBraveChallengePlayID, cards, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))

		# 额外的加成
		extraAttrBonus = ObjectYYBraveChallenge.extraAttrBonus(NormalBraveChallengePlayID, self.game, cards)
		battleModel = yield self.rpcYYHuodong.call_async("BraveChallengeStartBattle", role.normal_brave_challenge_record_db_id, role.id, NormalBraveChallengePlayID, floorID, monsterID, extraAttrBonus, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))
		battleModel["level"] = self.game.role.level
		self.game.battle = battleModel
		self.write({
			"model": {"brave_challenge_battle": battleModel}
		})


# 勇者挑战 结束战斗
class BraveChallengeBattleEnd(RequestHandlerTask):
	url = r"/game/brave_challenge/battle/end"

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)
		role = self.game.role

		battleID = self.input.get("battleID", None)
		if self.game.battle["id"] != battleID:
			raise ClientError("battleID error")

		floorID = self.input.get("floorID", None)
		if self.game.battle["floorID"] != floorID:
			raise ClientError("floorID error")

		result = self.input.get('result', None)
		cardStates = self.input.get('cardStates', None)
		monsterStates = self.input.get('monsterStates', None)  # {document.id: [hp, mp]}
		battleRound = self.input.get('battleRound', None)
		damage = self.input.get("damage", None)
		actions = self.input.get('actions', None)
		if isinstance(actions, list):
			actions = {idx + 1: v for idx, v in enumerate(actions)}

		if any([x is None for x in [result, cardStates, monsterStates, battleRound, actions]]):
			raise ClientError('param miss')

		cardstates = {}
		if isinstance(cardStates, list):
			for idx, state in enumerate(cardStates, 1):
				cardstates[idx] = state
		else:
			cardstates = cardStates

		formerMonsterStates = {}
		for idx, cardID in enumerate(self.game.battle['defence_cards'], 1):
			if cardID in monsterStates:
				formerMonsterStates[idx] = monsterStates[cardID]

		yyID = NormalBraveChallengePlayID

		# 战斗结算 跨天也正常结算
		data = {
			"floorID": floorID,
			"result": result,
			"card_states": cardstates,
			"monster_states": formerMonsterStates,
			"battle_round": battleRound,
			"damage": damage,
		}
		resp = yield self.rpcYYHuodong.call_async("BraveChallengeEndBattle", role.normal_brave_challenge_record_db_id, role.id, yyID, data, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))

		basecfg = ObjectYYBraveChallenge.getBaseCfg(yyID)

		eff = ObjectGainAux(self.game, {})
		extraEff = None
		if result == "win":
			cfg = csv.brave_challenge.floor[floorID]
			if resp["first_pass"]:
				eff += ObjectGainAux(self.game, cfg.firstAward)  # 首通额外奖励
			eff += ObjectYYBraveChallenge.getGold(yyID, self.game, cfg.repeatAward)
			if cfg.extraAward and resp["all_pass"]:
				extraEff = ObjectGainAux(self.game, cfg.extraAward)

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src="normal_brave_challenge_gate")
		if extraEff:
			yield effectAutoGain(extraEff, self.game, self.dbcGame, src="normal_brave_challenge_gate_extra")

		yyObj = None
		if resp["all_pass"]:
			# 通关次数
			ObjectYYBraveChallenge.active(yyObj, self.game, BraveChallengeDefs.PassTimes, 1)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.NormalBraveChallenge, 1)

		# 击杀
		ObjectYYBraveChallenge.active(yyObj, self.game, BraveChallengeDefs.KillCount, resp["kill"])
		# 阵亡
		ObjectYYBraveChallenge.active(yyObj, self.game, BraveChallengeDefs.DieCount, resp["die"])
		# 解锁卡池
		if len(resp["record"]["add"]):
			for cardID in resp["record"]["add"]:
				ObjectYYBraveChallenge.active(yyObj, self.game, BraveChallengeDefs.UnlockCard, cardID)

		ret = {
			"model": {"brave_challenge": resp["record"]},
			"view": {"award": eff.result, "all_pass": resp["all_pass"], "first_pass": resp["first_pass"], "extra_award": extraEff.result if extraEff else None},
		}
		self.write(ret)

		self.game.battle = None

		if resp["all_pass"] and resp["refresh"]:
			# 通关消耗回合数
			ObjectYYBraveChallenge.active(yyObj, self.game, BraveChallengeDefs.PassRound, resp["rank_info"]["round"])

			model = self.game.role.makeBraveChallengeRankModel(resp)
			yield ObjectServerGlobalRecord.sendRankingInfo(self.game, CrossNormalBraveChallengeRanking, model)		


# 勇者挑战 选择徽章
class BraveChallengeChoose(RequestHandlerTask):
	url = r"/game/brave_challenge/badge/choose"

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)
		role = self.game.role

		badgeID = self.input.get("badgeID", None)
		record = yield self.rpcYYHuodong.call_async("BraveChallengeChooseBadge", role.normal_brave_challenge_record_db_id, role.id, NormalBraveChallengePlayID, badgeID, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))
		# 累计获得勋章
		ObjectYYBraveChallenge.active(None, self.game, BraveChallengeDefs.GainBadge, 1)
		# 解锁卡池
		if len(record["add"]):
			for cardID in record["add"]:
				ObjectYYBraveChallenge.active(None, self.game, BraveChallengeDefs.UnlockCard, cardID)

		self.write({"model": {"brave_challenge": record}})


# 勇者挑战 认输
class BraveChallengeQuit(RequestHandlerTask):
	url = r"/game/brave_challenge/quit"

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)
		role = self.game.role

		record = yield self.rpcYYHuodong.call_async("BraveChallengeQuit", role.normal_brave_challenge_record_db_id, role.id, NormalBraveChallengePlayID, ObjectServerGlobalRecord.Singleton.normal_brave_challenge.get('startTime', 0))
		# 解锁卡池
		if len(record["add"]) > 0:
			for cardID in record["add"]:
				ObjectYYBraveChallenge.active(None, self.game, BraveChallengeDefs.UnlockCard, cardID)

		self.write({"model": {"brave_challenge": record}})


# 勇者挑战 购买次数
class BraveChallengeBuy(RequestHandlerTask):
	url = r"/game/brave_challenge/buy"

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)

		if not ObjectYYBraveChallenge.checkBuyTimes(self.game, NormalBraveChallengePlayID):
			raise ClientError("brave challenge buy times limit")

		costRMB = ObjectYYBraveChallenge.getBuyCost(self.game, NormalBraveChallengePlayID)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='brave_challenge_buy')
		ObjectYYBraveChallenge.addBuyTimes(self.game, NormalBraveChallengePlayID)


# 勇者挑战 排行榜
class BraveChallengeRank(RequestHandlerTask):
	url = r"/game/brave_challenge/rank"

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)

		resp = yield ObjectServerGlobalRecord.getRankingInfo(self.game, CrossNormalBraveChallengeRanking)

		self.write({
			"view":  resp,
		})


# 领取奖励
class BraveChallengeGetAward(RequestHandlerTask):
	url = r'/game/brave_challenge/award/get'

	@coroutine
	def run(self):
		if not checkOpen(self.game):
			raise ClientError(ErrDefs.huodongNoOpen)
		csvID = self.input.get('csvID', None)

		eff = ObjectYYBraveChallenge.getEffect(NormalBraveChallengePlayID, csvID, self.game)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='bravechallenge_award')

		self.write({'view': {'result': eff.result if eff else {}}})
