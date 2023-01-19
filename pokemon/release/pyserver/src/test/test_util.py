#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import struct
import platform


def print_env():
	print '-'*50
	print 'architecture', platform.architecture()
	print 'version', sys.version
	print 'maxint', sys.maxint
	print 'pointer bits', struct.calcsize("P") * 8
	print '-'*50


def print_linux_mem():
	import commands
	import re
	res = commands.getstatusoutput('ps aux|grep '+str(os.getpid()))[1].split('\n')[0]
	p = re.compile(r'\s+')
	l = p.split(res)
	print {
		'user': l[0],
		'pid': l[1],
		'cpu': l[2],
		'mem': l[3],
		'vsz': l[4],
		'rss': l[5],
		'start_time': l[6],
	}


def get_ps_mem():
	try:
		import psutil as ps
		p = ps.Process(pid=os.getpid())
		return p.as_dict(attrs=['memory_info', 'memory_percent'])['memory_info']
	except:
		pass
	return None


def calcsize(o):
	s = sys.getsizeof(o)
	if isinstance(o, (int, long, float, complex, str, unicode)):
		return s
	d = dir(o)
	if '__dict__' in d:
		vs = vars(o)
		for _, v in vs.iteritems():
			s += calcsize(v)
	elif 'iteritems' in d:
		for k, v in o.iteritems():
			s += calcsize(k) + calcsize(v)
	elif '__iter__' in d:
		for v in o:
			s += calcsize(v)
	return s
