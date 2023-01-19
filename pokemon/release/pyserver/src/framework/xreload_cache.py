#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import xreload as lib

__XPyPath = ['.']
__XPyCaches = {}

getFileBaseName = lambda s: os.path.splitext(os.path.basename(s))[0]

def listFiles(rootDir, ext = None):
	list_dirs = os.walk(rootDir)
	list_ret = {}
	for root, dirs, files in list_dirs:
		for f in files:
			pf = os.path.join(root, f)
			if not ext is None:
				if not f.endswith(ext):
					# print pf, '文件忽略'
					continue
			list_ret[pf] = os.path.getmtime(pf)
	return list_ret

def xreload_init(paths=['.']):
	global __XPyPath
	global __XPyCaches
	__XPyPath = paths
	__XPyCaches = {}
	for path in paths:
		files = listFiles(path, '.py')
		__XPyCaches.update(files)
	# import pprint
	# pprint.pprint(__XPyCaches)

def xreload_auto():
	global __XPyCaches
	newcache = {}
	changes = []
	for path in __XPyPath:
		filepaths = listFiles(path, '.py')
		olds = set(__XPyCaches)
		news = set(filepaths)
		newcache.update(filepaths)
		for path in olds & news:
			if filepaths[path] == __XPyCaches[path]:
				continue
			changes.append(path)
	xreload(changes)
	__XPyCaches = newcache
	return changes

def xreload(filepaths):
	filepaths = [(os.path.normpath(p), getFileBaseName(os.path.normpath(p))) for p in filepaths]
	# print 'xreload', filepaths
	modules = sys.modules.copy()
	for name, mod in modules.iteritems():
		modpath = getattr(mod, '__file__', None)
		if modpath is None:
			continue
		base1 = getFileBaseName(modpath)
		for path, base2 in filepaths:
			if base1 != base2 or modpath.find(path) < 0:
				continue
			print 'xreload patch', mod
			lib.xreload(mod)

def test():
	print os.getcwd()
	with open('_t.py', 'wb') as fp:
		fp.write('Test=111')

	xreload_init(os.getcwd())
	print __XPyCaches

	import _t
	print _t, _t.Test

	import time
	time.sleep(1)
	with open('_t.py', 'wb') as fp:
		fp.write('Test=222')

	print _t, _t.Test
	xreload_auto()
	print _t, _t.Test

	xreload_auto()

	import time
	time.sleep(1)
	with open('_t.py', 'wb') as fp:
		fp.write('Test=333')

	print _t, _t.Test
	xreload_auto()
	print _t, _t.Test

	with open('_t.py', 'wb') as fp:
		fp.write('Test=444')

	xreload(['_t'])
	print _t, _t.Test

if __name__ == '__main__':
	test()