#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2019 TianJi Information Technology Inc.
'''

import os
import sys


def main(path):
	if not os.path.exists(path):
		print 'no such file', path
		return

	with open(path, 'rb') as fp:
		data = fp.read()
		data = [x.strip() for x in data.split('\n')]
		ss = set(data)
		print len(data), len(ss)
		data = sorted(list(ss))

	with open(path + '.uniq', 'wb') as fp:
		fp.write('\n'.join(data))


if __name__ == '__main__':
	path = None
	if len(sys.argv) > 1:
		path = sys.argv[1]
	main(path)