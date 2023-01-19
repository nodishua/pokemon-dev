#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2019 TianJi Information Technology Inc.
'''
try:
	from invoke.vendor.six.moves.queue import Queue
except ImportError:
	from six.moves.queue import Queue

from invoke.util import ExceptionHandlingThread
from fabric.exceptions import GroupException
from fabric import Connection, ThreadingGroup, GroupResult

class MyConnection(Connection):
	def run(self, command, **kwargs):
		print '[%s] %s' % (self.original_host, command)
		return Connection.run(self, command, **kwargs)

def thread_worker(cxn, func, queue, args, kwargs):
	result = func(cxn)
	queue.put((cxn, result))

class MyThreadingGroup(ThreadingGroup):
	def __init__(self, *hosts, **kwargs):
		# gateway=Connection("root@43.129.178.245", connect_kwargs={"key_filename": "./ssh_key/key_kdjx_game_tw"}),
		self.extend([MyConnection(host, **kwargs) for host in hosts])

	def execute(self, func, *args, **kwargs):
		results = GroupResult()
		queue = Queue()
		threads = []
		for cxn in self:
			my_kwargs = dict(cxn=cxn, func=func, queue=queue, args=args, kwargs=kwargs)
			thread = ExceptionHandlingThread(
				target=thread_worker,
				kwargs=my_kwargs,
			)
			threads.append(thread)
		for thread in threads:
			thread.start()
		for thread in threads:
			thread.join()
		while not queue.empty():
			cxn, result = queue.get(block=False)
			results[cxn] = result
		excepted = False
		for thread in threads:
			wrapper = thread.exception()
			if wrapper is not None:
				cxn = wrapper.kwargs["kwargs"]["cxn"]
				results[cxn] = wrapper.value
				excepted = True
		if excepted:
			for cxn, v in results.iteritems():
				if v and isinstance(v, Exception):
					print cxn.original_host, v
			raise GroupException(results)
		return results
