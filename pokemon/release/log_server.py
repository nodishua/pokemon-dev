#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

import dev_patch
import framework
from framework.log import initLog

import argparse

def parseArgs():
	parser = argparse.ArgumentParser(description="%s\r\nGM server." % framework.__copyright__,\
		formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument('name', help='server name')
	args = parser.parse_args()
	return args

def main():
	args = parseArgs()
	initLog(args.name)

	from gm.server import LogServer
	server = LogServer(args.name)
	server.runLoop()


if __name__ == "__main__":
	main()
