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
		'game.cn.207': [
			('5edbb65f6cbae65dd787a310', 11248),
		],
	}
	server = rpcServer.game
	dbc = server.dbcGame
	if server.key not in Roles:
		raise Return('not one')
	roles = Roles[server.key]
	servID = int(server.key.split('.')[-1])

	ok, all = 0, len(roles)
	result = None
	for role_id, uid in roles:
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

				cards = game.cards.getCards([string2objectid('5f02c0ec6cbae66aac9eced1')])
				from game.object.game.gain import ObjectCostAux, ObjectGainAux
				cost = ObjectCostAux(game, {})
				cost.setCostCards(cards)
				if cost.isEnough() and cards:
					cost.cost(src='gm_fix')
					eff = ObjectGainAux(game, {925: 1})
					eff.gain(src='gm_fix')
				else:
					raise Exception('not enough')

				ObjectGame.popByRoleID(roleID)
				Session.discardSessionByAccountKey((game.role.area, game.role.account_id)) # real accountID, _syncLast
				Session.discardSessionByAccountKey((servID, accountID)) # fake accountID, _syncLast
				logger.info('fix role %d reset ok', uid)
				ok += 1
		except:
			logger.exception("role %d error" % uid)

	raise Return({'ok': ok, 'all': all})
	raise Return(result)



if __name__ == '__main__':
	print 'in __main__'
