#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Pay Queue
'''

import framework
from framework.log import logger
from framework.helper import objectid2string
from framework.dbqueue import TimerJoinableQueue
from game.globaldata import GameServInternalPassword
from payment.sdk.qq import SDKQQ
from payment.sdk.lunplay import SDKLunplay

from tornado.gen import coroutine, Return
from msgpackrpc.error import TransportError, TimeoutError

import datetime

NewState = 0
RetryRechargeState = 1
RechargedState = 2
RetryOrderFlagState = 3
EndState = 4
ErrorState = 5


class PayJoinableQueue(TimerJoinableQueue):
	PayFlushTimerSecs = 1
	Singleton = None

	def __init__(self, dbc, container, prefixs):
		TimerJoinableQueue.__init__(self, self.PayFlushTimerSecs)
		self.callback_time = 100 # PeriodicCallback
		self._dbc = dbc
		self.prefixs = prefixs
		self.container = container

		if PayJoinableQueue.Singleton is not None:
			raise ValueError('This is singleton object')
		PayJoinableQueue.Singleton = self

	def put(self, item, deadline=None):
		model, state = item
		if state == NewState:
			logger.info('{state}, channel `{channel}` account `{account}` server `{server_key}` role `{role}` recharge `{recharge_id}` order (`{order_id}`, `{id_}`) {amount:.2f} ext ({yy_id}, {csv_id}) queue'.format(state=state, account=objectid2string(model['account_id']), role=objectid2string(model['role_id']), id_=objectid2string(model['id']), **model))
		return TimerJoinableQueue.put(self, item, deadline)

	def join(self, closed=True):
		print 'PayJoinableQueue joining', self.qsize()
		return TimerJoinableQueue.join(self, closed)

	@coroutine
	def _process_item(self, item):
		model, state = item

		try:
			if state < RechargedState:
				# get game server rpc
				rpc = None
				name = model['server_key']
				if self.container.isExisted(name):
					rpc = self.container.getservice(name)
				else:
					for prefix in self.prefixs:
						if name.startswith(prefix):
							rpc = self.container.getserviceOrCreate(name)
							break
				if rpc is None:
					logger.error('no such game server %s', name)
					state = EndState
					raise Return(None)

				extInfo = None
				# 发送给game server更新QQ pfkey等信息
				if framework.is_qq_channel(model['channel']):
					extInfo = SDKQQ.parseDataTokenToGame(model['sdkmsg'], False)
				elif framework.is_lp_channel(model['channel']):
					extInfo = SDKLunplay.parseDataReProToGame(model['sdkmsg'])

				# game server recharge
				ret = yield rpc.call_async('PayForRecharge', GameServInternalPassword, model['channel'], model['account_id'], model['role_id'], model['recharge_id'], model['id'], model['amount'], extInfo, model['yy_id'], model['csv_id'])
				if ret == 'ok':
					state = RechargedState
				else:
					if state < RetryRechargeState:
						logger.error('`%s` game server error: %s', model['order_id'], ret)
						# 逻辑上出错，不可修复，打上bad_flag
						if ret.find('bad_flag') > 0:
							yield self._dbc.call_async('PayOrderBad', model['id'])
							raise Exception(ret)
						state = RetryRechargeState
						raise Return(None)
					else:
						raise Exception(ret)

			if state < EndState:
				# set order flag
				ret = yield self._dbc.call_async('PayOrderRecharge', model['id'])
				if not ret['ret']:
					if state < RetryOrderFlagState:
						logger.error('`%s` db server error: %s', model['order_id'], ret['err'])
						state = RetryOrderFlagState
						raise Return(None)
					else:
						raise Exception(ret)
				logger.info('channel `{channel}` account `{account}` server `{server_key}` role `{role}` recharge `{recharge_id}` order (`{order_id}`, `{id_}`) {amount:.2f} ext ({yy_id}, {csv_id}) recharge ok'.format(account=objectid2string(model['account_id']), role=objectid2string(model['role_id']), id_=objectid2string(model['id']), **model))
				state = EndState

		except Return:
			raise

		except (TransportError, TimeoutError):
			# 可能server掉线了
			logger.exception('pay queue exception, state %d, model %s' % (state, model))
			oldstate = state
			if not self._joined:
				self.io_loop.add_timeout(datetime.timedelta(seconds=5), lambda: self.put((model, oldstate)))
			state = ErrorState

		except:
			# 跳过，server运行期间不再处理
			# 比如, no such role这种异常
			logger.exception('pay queue exception, state %d, model %s' % (state, model))
			state = ErrorState

		finally:
			# 重新入队，再次尝试
			if state < EndState and not self._joined:
				self.put((model, state))

