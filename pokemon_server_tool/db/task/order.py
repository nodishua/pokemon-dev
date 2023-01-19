#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Account Server Database Task
'''

import db.redisorm as orm
import db.scheme.order as DBSO
from db.task import RPCTaskFactory


MyPayOrderKey = 'MyPayOrder'


class TOrderFactory(RPCTaskFactory):
	def payOrderAdd(self, data):
		order = None
		ret = {'ret': False}
		try:
			order = DBSO.PayOrder(**data)
			order.save()
			ret = {'ret': True, 'model': order.to_dict()}

		except orm.UniqueKeyViolation, e:
			orm.session.forget(order)
			order = DBSO.PayOrder.get_by(order_id=data['order_id'])
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__, 'model': order.to_dict()}

		except orm.ORMError, e:
			orm.session.forget(order)
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		return ret

	def payOrderRecharge(self, payID):
		order = None
		ret = {'ret': False}
		try:
			order = DBSO.PayOrder.get(payID)
			if order:
				order.recharge_flag = True
				return {'ret': True}

			else:
				return {'ret': False}

		except orm.ORMError, e:
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		finally:
			if order:
				order.save()
				orm.session.forget(order)

		return ret

	def payOrderBad(self, payID):
		order = None
		ret = {'ret': False}
		try:
			order = DBSO.PayOrder.get(payID)
			if order:
				order.bad_flag = True
				return {'ret': True}

			else:
				return {'ret': False}

		except orm.ORMError, e:
			ret = {'ret': False, 'err': str(e), 'err_type': type(e).__name__}

		finally:
			if order:
				order.save()
				orm.session.forget(order)

		return ret

	def myPayOrderCreate(self, payNoD, flush=False):
		r = orm.util.get_connection()
		if flush:
			r.delete(MyPayOrderKey)
		ret = True
		if payNoD:
			ret = r.hmset(MyPayOrderKey, payNoD)

	def myPayOrderAll(self):
		r = orm.util.get_connection()
		return r.hgetall(MyPayOrderKey)

