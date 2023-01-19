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
	parser = argparse.ArgumentParser(description="%s\r\nGame server." % framework.__copyright__,\
		formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument('name', help='server name')
	args = parser.parse_args()
	return args


def main():

	# def pre_reload():
	# 	print 'pre_reload !!!!!!!!!!'
	# 	print tornado.autoreload._reload_hooks

	# import tornado.autoreload
	# tornado.autoreload.add_reload_hook(pre_reload)

	args = parseArgs()
	initLog(args.name)

	from game.server import Server as GameServer
	server = GameServer(args.name)
	print '[%s] Server %s running ...' % (server.name, str(server.address))
	server.runLoop()



if __name__ == "__main__":
	main()
