#!/usr/bin/python
# -*- coding: utf-8 -*-

import re

try:
	import __pypy__
	is_pypy = True
except:
	is_pypy = False

disableReg = None
disableLib = None

def initFilter():
	global disableReg
	global disableLib

	filename = 'disable_words.txt'
	# import framework
	# if framework.__language__ == 'en':
	# 	filename = 'disable_words_en.txt'
	# elif framework.__language__ == 'tw':
	# 	filename = 'disable_words_tw.txt'
	# elif framework.__language__ == 'vn':
	# 	filename = 'disable_words_vn.txt'

	disableLib = []
	with open(filename, 'rb') as fp:
		disableLib = [x.strip().decode('utf8').lower() for x in fp.readlines()]
	disableLib = [x for x in disableLib if x]
	for i, x in enumerate(disableLib):
		# print i, len(disableLib), x
		# re.compile(x)
		disableLib[i] = x.replace("*", ".").replace("+", ".").replace("(", ".").replace(")", ".").replace("?", ".")
	disableReg = re.compile(u'|'.join(disableLib))

def filterName(uName):
	if len(uName.strip()) != len(uName):
		return True
	if uName.find(r'#') >= 0 or uName.find('\\') >= 0:
		return True

	try:
		#uName.encode('gbk')
		uName = uName.lower()
	except:
		return True

	# if is_pypy:
	# 	# re slow in pypy
	# 	for x in disableLib:
	# 		if uName.find(x) >= 0:
	# 			return True
	# else:
	# 	if disableReg.search(uName):
	# 		return True

	return False


if __name__ == '__main__':
	import time

	st = time.time()
	initFilter()
	print 'initFilter', time.time() - st

	names = [
		u' 1',
		u'毛泽东',
		u'藏 独',
		u'草泥马',
		u'操你妈',
		u'av',
		u'1024',
		u'1024bb',
		u'陌上丶花开',
		u'He先森丶',
		u'xx毛泽东xxx',
		u'爱的家庭',
		u'大參考',
		u'日gm',
		u'cu9988.com',
		u'200MYR',
		u'V信',
	]

	for name in names:
		print name, filterName(name)

	st = time.time()
	n = 1000
	for i in xrange(n):
		for name in names:
			filterName(name)

	cost = time.time() - st
	print 'filterName', cost, 's', cost/n*1000, 'ms'