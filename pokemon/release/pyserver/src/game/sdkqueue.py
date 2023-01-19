#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

DB LRU Queue
'''

from framework.log import logger
from framework.helper import toUTF8Dict
from framework.dbqueue import TimerJoinableQueue

from tornado.gen import coroutine
from tornado.curl_httpclient import CurlAsyncHTTPClient

import json
import urllib
import hashlib

class SDKJoinableQueue(TimerJoinableQueue):
	MailFlushTimerSecs = 1
	Singleton = None

	def __init__(self, clients, configs):
		TimerJoinableQueue.__init__(self, self.MailFlushTimerSecs)
		self._clients = clients
		self._configs = configs

		if SDKJoinableQueue.Singleton is not None:
			raise ValueError('This is singleton object')
		SDKJoinableQueue.Singleton = self

	def join(self, closed=True):
		print 'SDKJoinableQueue joining', self.qsize()
		return TimerJoinableQueue.join(self, closed)

	@coroutine
	def _process_item(self, item):
		sdk, info = item
		channel = sdk.pop('_channel', None)

		if channel == 'uc':
			cfg = self._configs[channel]
			client = self._clients[channel]

			sid = sdk['data']['sid']
			gameData = {
				"category": "loginGameRole",
				"content": {
					"roleLevel": str(info['role']['level']),
					"roleName": str(info['role']['name']),
					"zoneName": str(info['serv']['name']),
					"roleId": str(info['role']['id']),
					"zoneId": info['serv']['id'],
				}
			}
			gameData = json.dumps(gameData)
			gameData = urllib.quote(gameData)

			sign = hashlib.md5("gameData=%ssid=%s%s" % (gameData, sid, cfg['apiKey'])).hexdigest()
			sdk['data']['gameData'] = gameData
			sdk['sign'] = sign

			try:
				response = yield client.fetch(cfg['roleInfoURL'], method="POST", body=json.dumps(sdk))

				if response.error:
					logger.warning('uc sdk exdata error %s' % response.error)
				else:
					d = json.loads(response.body, object_hook=toUTF8Dict)
					if d['state']['code'] != 1:
						logger.warning('uc sdk exdata ret error %s' % (str(d['state'])))
			except:
				client.close()
				self._clients[channel] = CurlAsyncHTTPClient()
