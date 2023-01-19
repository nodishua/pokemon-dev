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
	parser = argparse.ArgumentParser(description="%s\r\nPayment server." % framework.__copyright__,\
		formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument('name', help='server name')
	args = parser.parse_args()
	return args

def main():
	args = parseArgs()
	initLog(args.name)

	from payment.server import Server as PaymentServer
	server = PaymentServer(args.name)
	print server.servName, 'HTTP listen at', server.httpAddress, 'running ...'
	server.runLoop()

if __name__ == "__main__":
	main()

