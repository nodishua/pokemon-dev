#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

import multiprocessing
from multiprocessing import Queue

from .server import Server


class Process(multiprocessing.Process):
	def __init__(self, name):
		self.serverName = name
		self._q = Queue(1)

		multiprocessing.Process.__init__(self)
		self.daemon = True

	def run(self):
		print 'Sub %x Start'% self.pid
		handleServer = Server(self.serverName, self._q)
		handleServer.start()

	def stop(self):
		if self._q.full():
			return
		self._q.put('over')
