#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import re
from collections import defaultdict
import codecs

# BOM header will cause syntax error under Mac, iOS

def listFiles(rootDir, ext='.lua'):
	list_dirs = os.walk(rootDir)
	list_ret = []
	for root, dirs, files in list_dirs:
		for f in files:
			if ext and f.endswith(ext):
				list_ret.append(os.path.join(root, f))
	return list_ret


BOMs = {
	'BOM': codecs.BOM,
	'BOM_BE': codecs.BOM_BE,
	'BOM_LE': codecs.BOM_LE,
	'BOM_UTF8': codecs.BOM_UTF8,
	'BOM_UTF16': codecs.BOM_UTF16,
	'BOM_UTF16_BE': codecs.BOM_UTF16_BE,
	'BOM_UTF16_LE': codecs.BOM_UTF16_LE,
	'BOM_UTF32': codecs.BOM_UTF32,
	'BOM_UTF32_BE': codecs.BOM_UTF32_BE,
	'BOM_UTF32_LE': codecs.BOM_UTF32_LE,
}

def removeBOM(filename):
	data = None
	with open(filename, 'rb') as fp:
		data = fp.read(10)
		flag = False
		for h, x in BOMs.iteritems():
			if data.find(x) >= 0:
				flag = True
				break
		if flag:
			data += fp.read()
			data = data[len(x):]
			print filename, 'has', h
		else:
			data = None
	if data:
		with open(filename, 'wb') as fp:
			fp.write(data)
	return data is not None

def main():
	# files1 = listFiles('./cocos')
	# files2 = listFiles('./scripts')
	# files3 = listFiles('./updater')

	for filename in listFiles('./'):
		removeBOM(filename)

if __name__ == '__main__':
	main()
