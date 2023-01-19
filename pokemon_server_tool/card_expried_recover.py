#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
reload(sys)
sys.setdefaultencoding('utf8')

sys.path.insert(0, '../server/src')
sys.path.insert(0, '../server')

import msgpack
from service_forward import open_forward, objectid2string, string2objectid
import itertools
from tornado.ioloop import IOLoop
from tornado.gen import coroutine, Return, sleep
from tornado.concurrent import Future

import framework
framework.__language__ = 'cn'
from framework.csv import csv, ConstDefs
import math
import copy
from datetime import datetime
class ObjectCard(object):
	CardsMarkStarMap = {} # {(starTypeID, star): csv}
	CardStar2FragMap = {} #{(type,star):csv}
	@classmethod
	def classInit(cls):
		# 卡牌星级
		cls.CardsMarkStarMap = {}
		for i in csv.card_star:
			csvStar = csv.card_star[i]
			cls.CardsMarkStarMap[(csvStar.typeID, csvStar.star)] = csvStar

		# 卡牌星级转换碎片数
		cls.CardStar2FragMap = {}
		for i in csv.card_star2frag:
			csvCardFrag = csv.card_star2frag[i]
			cls.CardStar2FragMap[(csvCardFrag.type, csvCardFrag.getStar)] = csvCardFrag

	@classmethod
	def getStarFragCfg(cls, type, star):
		return cls.CardStar2FragMap.get((type, star), None)
ObjectCard.classInit()

# 计算需要扣除的魂石和金币
def decompose_star(card):
	frags = {}
	items = {}
	cards = 0

	# 1.初始星级
	cfg = csv.cards[card.card_id]
	if cfg.fragID == 0:
		raise ServerError('cards.csv no fragID')
	starFragCfg = ObjectCard.getStarFragCfg(cfg.fragNumType, card.getstar)
	frags[cfg.fragID] = starFragCfg.baseFragNum

	for i in xrange(card.getstar, card.star):
		csvStar = ObjectCard.CardsMarkStarMap.get((cfg.starTypeID, i), None)
		cards += csvStar.costCardNum
		# 2.升星消耗材料
		items['gold'] = items.get('gold', 0) + csvStar.gold
		for k, v in csvStar.costItems.iteritems():
			items[k] = items.get(k, 0) + v

	# 3.消耗系列整卡
	cards -= sum(card.cost_universal_cards.values())
	starFragCfg = ObjectCard.getStarFragCfg(cfg.fragNumType, 1) # 消耗的整卡都当1星处理
	frags[cfg.fragID] += starFragCfg.baseFragNum * cards

	# 4.消耗万能整卡 （暂不处理）

	# 将碎片转换为魂石
	for fragID, num in frags.iteritems():
		cfg = csv.fragments[fragID]
		for k, v in cfg.decomposeGain.iteritems():
			items[k] = items.get(k, 0) + v * num

	for k, v in items.iteritems():
		items[k] = int(math.ceil(ConstDefs.rebirthRetrunProportion2 * v))
	return items

def dictSum(d1, d2):
	''' 把d2的内容加到d1里'''
	t = copy.copy(d2)
	for key in d1:
		if key in t:
			t[key] += d1[key]
	d1.update(t)

def online():
	with open_forward('cn') as client:
		@coroutine
		def run():
			from framework.object import ObjectDicAttrs

			servKey = "game.cn_qd.465"
			uID = "11170"
			roleID = "5ea65091820c4854ae2a05bb"
			reCardIDs = []  # 指定恢复，为空则全部恢复

			# # 部分一: 升星卡牌直接恢复
			# cost = {}
			# cardIDs = []
			# # 查询
			# resp = yield client.call_async('GMRoleCardExpiredGet', roleID, service_id=servKey)
			# for card in resp:
			# 	cardID = objectid2string(card['id'])
			# 	if not reCardIDs or (cardID in reCardIDs):
			# 		print 'card', cardID, card['card_id'], datetime.fromtimestamp(card['delete_time']), card['star'], csv.cards[card['card_id']].name
			# 		card = ObjectDicAttrs(card)
			# 		print 'cost', decompose_star(card)
			# 		dictSum(cost, decompose_star(card))
			# 		cardIDs.append(cardID)
			# 		print '='* 20
			# print '-' * 10, "rise_star", '-' * 10
			# print '【cards】:', cardIDs
			# print '【cards num】:', len(cardIDs)
			# print '【all cost】:', cost
			# print '-' * 10, "rise_star", '-' * 10

			# # 扣除魂石和金币， 不成功则不恢复
			# costResp = client.call_async('GMRollbackRoleItem', uID, cost, {}, {}, service_id=servKey)
			# print "rise_star_card: ", costResp
			# if not costResp[0]:
			# 	return

			# # 恢复, 恢复前要扣除对应的魂石和金币
			# successNum = 0
			# for card in resp:
			# 	cardID = objectid2string(card['id'])
			# 	if not reCardIDs or (cardID in reCardIDs):
			# 		resp = yield client.call_async('GMRecoverRoleCard', roleID, cardID, service_id=servKey)
			# 		print cardID, resp
			# 		if resp == "success":
			# 			successNum += 1
			# print '-'* 10
			# print '【success num】:', successNum
			# print '-'* 10

			# 部分二: 未升星卡牌补发
			servs = servKey.split('.')
			rets = []
			# TODO 这个我是预先把cost for部分用fabfile写入文件了，或者直接抠出来贴到rets也行
			logFile = "out/%s_%s_%s_card_decompose.log" % (servs[1], servs[2], uID)
			with open(logFile, "r") as f:
				for line in f.readlines():
					line = line.strip('\n')  # 去掉换行符
					costDict = eval(line)
					rets.append(costDict)
			targetStar = 2  # 指定星级及以上
			costCardNumAll = 0
			costItems = {}
			retCards = []
			for ret in rets:
				cards = ret.get('cards', {})
				costCardNumAll += len(cards)
				for card in cards:
					star = card.get('star', 0)
					cardCsvId = card.get('id', 0)
					cfg = csv.cards[cardCsvId]
					if cfg and star == cfg.star and star >= targetStar:  # 如果想指定单个星级改为 ==
						# 计算魂石消耗
						cfgFrag = csv.fragments[cfg.fragID]
						for k, v in cfgFrag.decomposeGain.iteritems():
							costItems[k] = costItems.get(k, 0) + v * cfgFrag.combCount
						# 返回卡牌统计
						retCards.append({'id': cardCsvId})
			cards = {'cards': retCards}
			print '-' * 10, "no_rise_star", '-' * 10
			print '【ret cards num】:', len(retCards)
			print '【all cards num】:', costCardNumAll
			print '【all cost】:', costItems
			print '【return cards】:', cards
			print '-' * 10, "no_rise_star", '-' * 10

			# 补发，先查询确认下消耗和补发卡再执行
			# resp = client.call_async('GMRollbackRoleItem', uID, costItems, cards, {}, service_id=servKey)
			# print "no_rise_star_card: ", resp

		IOLoop.current().run_sync(run)


if __name__ == "__main__":
	online()
