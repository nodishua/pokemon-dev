#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Game Server Database Task
'''

from framework.log import logger
import db.redisorm as orm
from db.scheme import models
from db.task import RPCTaskFactory, DBTaskError

import gc
import time
import random
import traceback


class Timer(object):
	def __init__(self, name):
		self.name = name

	def __enter__(self):
		self.start = time.clock()
		return self

	def __exit__(self, *args):
		self.end = time.clock()
		self.interval = self.end - self.start
		print '[db profile]', self.name, 'cost', self.interval, 'ms'


def time_profile(func):
	def newfunc(*args, **keywords):
		with Timer(str(func)):
			return func(*args, **keywords)
	return newfunc


class TGameFactory(RPCTaskFactory):
	# @time_profile
	def dbCreate(self, model, kvs, forget=False):
		ret = None
		obj = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			obj = modelCls(**kvs)
			obj.save()

			ret = {'ret': True, 'model': obj.to_dict()}

			if forget:
				orm.session.forget(obj)

		except Exception, e:
			if obj:
				orm.session.forget(obj)
			logger.exception('dbCreate Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbUpdate(self, model, pkey, kvs, forget=False):
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			obj = modelCls.get(int(pkey))
			if obj is None:
				raise DBTaskError('no such object %s[%d]' % (model, int(pkey)))

			for k, v in kvs.iteritems():
				if k not in modelCls._columns:
					raise DBTaskError('no such column %s.%s' % (model, k))
				try:
					setattr(obj, k, v)
				except:
					raise DBTaskError('column %s.%s set error' % (model, k))

			ret = {'ret': True}

			if forget:
				obj.save(True)
				orm.session.forget(obj)
			else:
				obj.save()

		except Exception, e:
			logger.exception('dbUpdate Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbRead(self, model, pkey, forget=False):
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			obj = modelCls.get(int(pkey))
			if obj is None:
				raise DBTaskError('no such object %s[%d]' % (model, int(pkey)))

			ret = {'ret': True, 'model': obj.to_dict()}

			if forget:
				orm.session.forget(obj)

		except Exception, e:
			logger.exception('dbRead Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbMultipleRead(self, model, pkeys):
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			objL = modelCls.get(pkeys)
			if objL and not isinstance(objL, list):
				objL = [objL]

			if not objL:
				return {'ret': False, 'err': 'has nones'}

			ret = {'ret': True, 'models': {o.id: o.to_dict() for o in objL}}

		except Exception, e:
			logger.exception('dbMultipleRead Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbMultipleReadKeys(self, model, pkeys, keys):
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			objL = modelCls.get(pkeys)
			if objL and not isinstance(objL, list):
				objL = [objL]

			if not objL:
				return {'ret': False, 'err': 'has nones'}

			objsD = {}
			for obj in objL:
				if obj:
					objsD[obj.id] = {}
					for key in keys:
						objsD[obj.id][key] = getattr(obj, key)
					objsD[obj.id]['id'] = getattr(obj, 'id')

			if not objsD:
				return {'ret': False, 'err': 'has nones d'}

			ret = {'ret': True, 'models': objsD}

		except Exception, e:
			logger.exception('dbMultipleReadKeys Exception model %s pkeys %s keys %s', model, pkeys, keys)
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbReadBy(self, model, kvs):
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			if len(kvs) == 1:
				objL = modelCls.get_by(**kvs)
			else:
				objL = modelCls.query.filter(**kvs).all()

			if not isinstance(objL, list):
				objL = [objL]

			ret = {'ret': True, 'models': [x.to_dict() for x in objL if x]}

		except Exception, e:
			logger.exception('dbReadBy Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbReadAll(self, model):
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			objL = []
			pMax = modelCls.get_primary_max()
			for pkID in xrange(pMax+1):
				mol = modelCls.get(pkID)
				if mol:
					objL.append(mol)

			ret = {'ret': True, 'models': [x.to_dict() for x in objL if x]}

		except Exception, e:
			logger.exception('dbReadAll Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret


	# @time_profile
	def dbReadByPattern(self, model, kvs, chooseSize=None):
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			query = modelCls.query.like(**kvs)

			if chooseSize > 0:
				offest = 0
				count = query.count()
				if chooseSize < count:
					offest = random.randint(0, count - chooseSize)
				query = query.limit(offest, chooseSize)

			objL = query.all()

			ret = {'ret': True, 'models': [x.to_dict() for x in objL if x]}

		except Exception, e:
			logger.exception('dbReadByPattern Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbReadRangeBy(self, model, kvs, chooseSize=None):
		'''
		msgpack 不区分tuple和list，统一为list
		rom 区分tuple和list，tuple作为区间，list作为集合
		'''
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			for k, v in kvs.iteritems():
				if isinstance(v, list):
					kvs[k] = tuple(v)

			query = modelCls.query.filter(**kvs)

			if chooseSize > 0:
				offest = 0
				count = query.count()
				if chooseSize < count:
					offest = random.randint(0, count - chooseSize)
				query = query.limit(offest, chooseSize)

			objL = query.all()

			ret = {'ret': True, 'models': [x.to_dict() for x in objL]}

		except Exception, e:
			logger.exception('dbReadRangeBy Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbReadKeysRangeBy(self, model, kvs, keys, chooseSize=None):
		'''
		msgpack 不区分tuple和list，统一为list
		rom 区分tuple和list，tuple作为区间，list作为集合
		'''
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			for k, v in kvs.iteritems():
				if isinstance(v, list):
					kvs[k] = tuple(v)

			query = modelCls.query.filter(**kvs)

			if chooseSize > 0:
				offest = 0
				count = query.count()
				if chooseSize < count:
					offest = random.randint(0, count - chooseSize)
				query = query.limit(offest, chooseSize)

			objL = query.all()

			objsD = {}
			for obj in objL:
				objsD[obj.id] = {}
				for key in keys:
					objsD[obj.id][key] = getattr(obj, key)
				objsD[obj.id]['id'] = getattr(obj, 'id')

			ret = {'ret': True, 'models': objsD}

		except Exception, e:
			logger.exception('dbReadRangeBy Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbReadNearBy(self, model, key, lrval, size=1):
		ret = []
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				raise DBTaskError('no such model %s' % model)

			# 往小的取
			range = ('-inf', lrval[0])
			order = '-%s' % key
			objL = modelCls.query.filter(**{key: range}).order_by(order).limit(0, size).all()
			if objL:
				ret = [x.to_dict() for x in objL]
				if len(objL) >= size:
					return {'ret': True, 'models': ret}

			# 往大的取
			range = (lrval[1], '+inf')
			order = key
			objL = modelCls.query.filter(**{key: range}).order_by(order).limit(0, size).all()
			if objL:
				ret += [x.to_dict() for x in objL]

			if ret:
				return {'ret': True, 'models': ret}
			return {'ret': False}

		except Exception, e:
			logger.exception('dbReadNearBy Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return None

	# @time_profile
	def dbDelete(self, model, pkeys):
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				return {'ret': False, 'err': 'no such model %s' % model}

			modelCls.delete_by_ids(pkeys, True)

		except Exception, e:
			logger.exception('dbDelete Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return {'ret': True}

	# @time_profile
	def dbPkeyMaxDelete(self, model, lastPkeyMax):
		nowPkeyMax = 1
		deleteCount = 0
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				return {'ret': False, 'err': 'no such model %s' % model}

			nowPkeyMax = modelCls.get_primary_max()
			for dbID in xrange(lastPkeyMax, nowPkeyMax+1):
				dbmodel = modelCls.get(dbID)
				if dbmodel:
					dbmodel.delete()
					deleteCount += 1

		except Exception, e:
			logger.exception('dbPkeyMaxDelete Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return {'ret': True, 'pkeyMax': nowPkeyMax, 'deleteCount': deleteCount}

	# @time_profile
	def dbCommitObject(self, model, pkey):
		ret = None
		try:
			modelCls = models.get(model, None)
			if modelCls is None:
				return {'ret': False, 'err': 'no such model %s' % model}

			# 从session中取，不会重新从数据库中取回来
			pkey = modelCls.get_pkey(pkey)
			obj = orm.session.get(pkey)
			if obj:
				obj.save(True)
				orm.session.forget(obj)

			logger.debug('dbCommitObject %s', pkey)

			ret = {'ret': True}

		except Exception, e:
			logger.exception('dbCommitObject Exception')
		return ret

	# @time_profile
	def dbFlush(self, full=True, all=True):
		orm.session._init()
		ocount = len(orm.session.known)
		cchanges = orm.session.flush(full=full, all=all, logger=logger)
		logger.info('dbFlush %d objects %d columns change', ocount, cchanges)
		logger.info('Redis Session %d known, %d wknown', len(orm.session.known), len(orm.session.wknown))

	# @time_profile
	def dbCommit(self, full=True, all=True):
		orm.session._init()
		ocount = len(orm.session.known)
		cchanges = orm.session.commit(full=full, all=all, logger=logger)
		gc.collect()
		logger.info('dbCommit %d objects %d columns change and forget', ocount, cchanges)
		logger.info('Redis Session %d known, %d wknown', len(orm.session.known), len(orm.session.wknown))


	def dbRedisZrevrange(self, rankName, start, end, withScores):
		try:
			ret = orm.util.get_connection().zrevrange(rankName,start-1,end-1,withScores)
		except Exception, e:
			logger.exception('dbRedisZrevrange Exception')
		if rankName == "Rank_card1fight":
			if withScores:
				return [(int(o[0]),int(o[1]))for o in ret]
			else:
				return [int(o) for o in ret]
		else:
			if withScores:
				return [(1000000-int(o[0]),int(o[1]))for o in ret]
			else:
				return [1000000-int(o) for o in ret]

	def dbRedisZrevrangebyscore(self, rankName, max, min, withScores):
		try:
			ret = orm.util.get_connection().zrevrangebyscore(rankName, max, min, withscores=withScores)
		except Exception, e:
			logger.exception('dbRedisZrevrangebyscore Exception')
		if rankName == "Rank_card1fight":
			if withScores:
				return [(int(o[0]),int(o[1]))for o in ret]
			else:
				return [int(o) for o in ret]
		else:
			if withScores:
				return [(1000000-int(o[0]),int(o[1]))for o in ret]
			else:
				return [1000000-int(o) for o in ret]

	def dbRedisZaddGetRank(self,rankName,key,score):
		try:
			if rankName == "Rank_card1fight":
				orm.util.get_connection().zadd(rankName,key,score)
			else:
				orm.util.get_connection().zadd(rankName,'%06d'%(1000000-key),score)
		except Exception, e:
			logger.exception('dbRedisZadd Exception')

		return self.dbRedisZrevrank(rankName,key)

	def dbRedisZrevrank(self,rankName,key):
		try:
			if rankName == "Rank_card1fight":
				ret = orm.util.get_connection().zrevrank(rankName,key)
			else:
				ret = orm.util.get_connection().zrevrank(rankName,'%06d'%(1000000-key))
		except Exception, e:
			logger.exception('dbRedisZrevrank Exception')
			ret = -1
		if ret == None:
			return 0

		return ret + 1

	def dbRedisZScore(self,rankName,key):
		ret = None
		try:
			if rankName == "Rank_card1fight":
				ret = orm.util.get_connection().zscore(rankName,key)
			else:
				ret = orm.util.get_connection().zscore(rankName,'%06d'%(1000000-key))
		except Exception, e:
			logger.exception('dbRedisZScore Exception')
			ret = 0
		if ret == None:
			return 0

		return ret

	def dbRedisZremrangebyrank(self,rankName,start,end):
		try:
			ret = orm.util.get_connection().zremrangebyrank(rankName, start, end)
		except Exception, e:
			logger.exception('dbRedisZremrangebyrank Exception')

		return ret

	def dbGetRankSize(self,rankName,start, end):
		ret = None
		try:
			ranks = []
			scores = self.dbRedisZrevrange(rankName, start, end, True)
			if rankName == "Rank_card1fight":
				cardIDL = [o[0] for o in scores]
				dbCards = self.dbMultipleReadKeys('RoleCard', cardIDL, ['role_db_id', 'card_id', 'advance', 'star', 'level'])
				if not dbCards['ret']:
					return {'ret': False, 'err': 'error cardIDL:%s'%cardIDL}
				dbCards = dbCards['models']
				roleIDL = [o['role_db_id'] for o in dbCards.values()]
				dbRoles = self.dbMultipleReadKeys('Role', roleIDL, ['logo', 'name', 'level', 'vip_level', 'union_db_id'])
				if not dbRoles['ret']:
					return {'ret': False, 'err': 'error roleIDL:%s'%roleIDL}
				dbRoles = dbRoles['models']

				for key,score in scores:
					card = dbCards[key]
					role = dbRoles[card['role_db_id']]
					model = [card['role_db_id'],role['logo'], role['name'], role['level'], role['vip_level']]
					unionName = None
					if role['union_db_id'] > 0:
						unionData = self.dbMultipleReadKeys('Union', role['union_db_id'],['name'])
						if unionData['ret']:
							unionName = unionData['models'][role['union_db_id']]['name']
					model.append(unionName)
					model.append(score)
					model.append({'slim':{
							'card_db_id': key,
							'card_id': card['card_id'],
							'advance': card['advance'],
							'star': card['star'],
							'level': card['level'],
						}})
					ranks.append(tuple(model))
			else:
				roleIDL = [o[0] for o in scores]
				dbRoles = self.dbMultipleReadKeys('Role', roleIDL, ['logo', 'name', 'level', 'vip_level', 'union_db_id'])
				if not dbRoles['ret']:
					return {'ret': False, 'err': 'error roleIDL:%s'%roleIDL}
				for key,score in scores:
					info = dbRoles['models'][key]
					model = [key, info['logo'], info['name'], info['level'], info['vip_level']]
					unionName = None
					if info['union_db_id'] > 0:
						unionData = self.dbMultipleReadKeys('Union', info['union_db_id'],['name'])
						if unionData['ret']:
							unionName = unionData['models'][info['union_db_id']]['name']
					model.append(unionName)
					model.append(score)
					ranks.append(tuple(model))
			ret = {'ret': True, 'models':ranks}
		except Exception, e:
			logger.exception('dbGetRankSize Exception')
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret

	# @time_profile
	def dbReadSlimRoles(self, roleIDL):
		ret = None
		try:
			dbRoles = self.dbMultipleReadKeys('Role', roleIDL, ['logo', 'name', 'level', 'vip_level', 'battle_cards', 'union_db_id', 'pvp_record_db_id', 'battle_fighting_point'])
			if not dbRoles['ret']:
				return {'ret': False, 'err': 'error roleIDL:%s'%roleIDL}
			model = {}
			dbRoles = dbRoles['models']
			for k,v in dbRoles.iteritems():
				model[k] = {'model':{
						'roleID': k,
						'logo': v['logo'],
						'name': v['name'],
						'level': v['level'],
						'union_db_id': v['union_db_id'],
						'vip_level': v['vip_level'],
						'fight': v['battle_fighting_point'],
					}
				}

				fightgo = 0
				if v['pvp_record_db_id'] > 0:
					pvpData = self.dbMultipleReadKeys('PVPRecord', v['pvp_record_db_id'],['fightgo_val'])
					if pvpData['ret']:
						fightgo = pvpData['models'][v['pvp_record_db_id']]['fightgo_val']
				model[k]['model']['fightgo'] = fightgo

				reCards = filter(None,v['battle_cards'])
				dbCards = self.dbMultipleReadKeys('RoleCard', reCards, ['card_id', 'advance', 'star', 'level', 'fighting_point', 'skin_id'])
				if not dbCards['ret']:
					return {'ret': False, 'err': 'error reCards:%s,roleID:%d'%(reCards,v['id'])}
				dbCards = dbCards['models']
				defenceCards = []
				cardsSlimAttrs = {}
				for cardID in v['battle_cards']:
					if cardID:
						card = dbCards[cardID]
						defenceCards.append((cardID, card['card_id'], card['skin_id']))
						cardsSlimAttrs[cardID] = {
							'level': card['level'],
							'fighting_point': card['fighting_point'],
							'advance': card['advance'],
							'star': card['star'],
							'skin_id': card['skin_id'],
						}
					else:
						defenceCards.append((0, 0, 0))
				model[k]['defenceCards'] = defenceCards
				model[k]['cardsSlimAttrs'] = cardsSlimAttrs

			ret = {'ret': True, 'models':model}

		except Exception, e:
			logger.exception('dbReadSlimRoles Exception roleIDL %s', roleIDL)
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret


	# @time_profile
	def dbReadSlimCards(self, cardIDL):
		ret = None
		try:
			dbCards = self.dbMultipleReadKeys('RoleCard', cardIDL, ['role_db_id', 'card_id', 'advance', 'star', 'develop', 'level', 'innate_skill_level', 'skills', 'fetters', 'fighting_point', 'db_attrs', 'skin_id'])
			if not dbCards['ret']:
				return {'ret': False, 'err': 'error cardIDL:%s'%cardIDL}
			model = {}
			dbCards = dbCards['models']
			roleIDL = []
			for k,v in dbCards.iteritems():
				roleIDL.append(v['role_db_id'])
				model[k] = {'card': v}

			dbRoles = self.dbMultipleReadKeys('Role', roleIDL, ['logo', 'name', 'level', 'vip_level', 'union_db_id'])
			if not dbRoles['ret']:
				return {'ret': False, 'err': 'error roleIDL:%s'%roleIDL}

			dbRoles = dbRoles['models']
			for k,v in dbCards.iteritems():
				role = dbRoles[v['role_db_id']]
				model[k].update({'model':{
					'roleID': v['role_db_id'],
					'logo': role['logo'],
					'name': role['name'],
					'level': role['level'],
					'vip_level': role['vip_level'],
				}})

				unionName = None
				if role['union_db_id'] > 0:
					unionData = self.dbMultipleReadKeys('Union', role['union_db_id'],['name'])
					if unionData['ret']:
						unionName = unionData['models'][role['union_db_id']]['name']
				model[k]['model']['union_name'] = unionName

			ret = {'ret': True, 'models':model}

		except Exception, e:
			logger.exception('dbReadSlimCards Exception cardIDL %s', cardIDL)
			return {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'err_traceback': traceback.format_exc()}
		return ret