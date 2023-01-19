#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
huanxi2394fd79a1ad32ff2e2db603da
'''

from framework.log import logger
from tornado.gen import coroutine, Return

@coroutine
def exec_coroutine(rpcServer):
	from framework.log import logger
	from tornado.gen import coroutine, Return
	from game.object.game import ObjectGame
	from game.session import Session
	from game.object.game.gain import ObjectCostAux, ObjectGainAux
	from game.object.game.explorer import ObjectExplorer
	from framework.csv import csv
	from framework.helper import string2objectid

	@coroutine
	def login(server, servID, accountID, roleID):
		from game.handler._game import GameLogin

		class FakeGameLogin(GameLogin):
			def __init__(self, application, session):
				self.application = application
				self.session = session
				self.accountID = None # 为了fix时用role_id查找
				# self.accountID = accountID
				self.roleID = roleID
				self.input = {}

			@property
			def dbcGame(self):
				return self.application.dbcGame

			@property
			def rpcPVP(self):
				return self.application.rpcPVP

			@property
			def game(self):
				return self.session.game

			def write(self, view):
				pass

		session = Session(servID, accountID, str(accountID), accountID, {}, {})
		Session.setSession(session)

		handler = FakeGameLogin(server.application, session)
		yield handler.loading()

	Roles = {
		'game.cn.1': [
			('5de720ae5ec29639c547f7f9', 10114, [(26, {4000: 105, 4073: 2}), (16, {4000: 290, 4052: 4})]),
		],
	}
	server = rpcServer.game
	dbc = server.dbcGame
	if server.key not in Roles:
		raise Return('not one')
	roles = Roles[server.key]
	servID = int(server.key.split('.')[-1])

	ok, all = 0, len(roles)
	for role_id, uid, ops in roles:
		account_id = role_id
		accountID, roleID = string2objectid(account_id), string2objectid(role_id)
		try:
			game = ObjectGame.ObjsMap.get(roleID, None)
			if game is None:
				yield login(server, servID, accountID, roleID)
				logger.info('role %d fake login', uid)
			game = ObjectGame.ObjsMap.get(roleID, None)
			if game is None:
				logger.warning("role %d no load !!!" % uid)
				raise Return(None)
			if game:
				role = game.role

				if role.uid != uid:
					raise Exception('id error')


				### fix begin
				logger.info("---------- %s %d" % (server.key, uid))
				explorers = role.explorers
				expSet = set()
				for componentCsvID, costD in ops:
					cfg = csv.explorer.component[componentCsvID]
					explorerCsvID, maxLevel = ObjectExplorer.ComponentExplorerMap.get(componentCsvID, ())
					if not explorerCsvID:
						continue

					explorer = explorers.get(explorerCsvID, {'advance': 0, 'components': {}})
					components = explorer['components']
					oldlevel = components.get(componentCsvID, 0)
					if oldlevel == 0:
						continue

					logger.info('before fix_component %s role %d component %d %s' % (server.key, uid, componentCsvID, components))

					expSet.add(explorerCsvID)
					level = max(0, oldlevel - 1)
					components[componentCsvID] = level
					logger.info("fix_component %d to level %d" % (componentCsvID, level))
					retCost = ObjectGainAux(game, costD)
					retCost.gain(src='fix_component_revert')

					# 消耗
					# costItems = csv.explorer.component_level[oldlevel]['costItemMap%d' % cfg.strengthCostSeq] # TODO

					game.explorer._componentAttrAddition = {}
					logger.info('after fix_component %s role %d component %d %s' % (server.key, uid, componentCsvID, components))

				for explorerCsvID in expSet:
					cfg = csv.explorer.explorer[explorerCsvID]
					if explorerCsvID not in explorers:
						continue
					explorer = explorers[explorerCsvID]
					components = explorer.get('components', {})
					advance = explorer.get('advance', 0)
					advanceMax = 999
					for componentCsvID in cfg.componentIDs:
						advanceMax = min(advanceMax, components.get(componentCsvID, 0))
					if advanceMax == 999:
						advanceMax = 0

					if advanceMax >= advance:
						continue

					logger.info('before fix_explorer %s role %d explorer %d %s' % (server.key, uid, explorerCsvID, explorer))

					for i in range(advance, advanceMax, -1):
						# 消耗
						costItems = csv.explorer.explorer_advance[i]['costItemMap%d' % cfg.advanceCostSeq]
						explorer['advance'] = i - 1
						logger.info("fix_explorer %d to advance %d" % (explorerCsvID, i - 1))

						retCost = ObjectGainAux(game, costItems)
						retCost.gain(src='fix_explorer_revert')

					game.explorer._passive_skills = None
					game.explorer._passive_skills_global = None
					game.explorer._effects = None
					game.explorer._explorerAttrAddition = {}
					logger.info('after fix_explorer %s role %d explorer %d %s' % (server.key, uid, explorerCsvID, explorer))

				# 属性加成
				for card in game.cards.getCards(game.role.cards):
					card.calcExplorerComponentAttrsAddition(card, game.explorer)
					card.onUpdateAttrs()
				### fix end

				ObjectGame.popByRoleID(roleID)
				Session.discardSessionByAccountKey((game.role.area, game.role.account_id)) # real accountID, _syncLast
				Session.discardSessionByAccountKey((servID, accountID)) # fake accountID, _syncLast
				logger.info('fix_explorer %s role %d reset ok' % (server.key, uid))
				ok += 1
		except:
			logger.exception("fix_explorer %s role %d error" % (server.key, uid))

	raise Return({'ok': ok, 'all': all})



if __name__ == '__main__':
	print 'in __main__'
