#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.
'''


# {reg: handle,}
Regs = {}

def addReHandler(reg, handler):
	if reg in Regs:
		raise 'already exist %s'% reg
	Regs[reg] = handler

def processLine(line):
	for reg, handler in Regs.iteritems():
		if reg.search(line):
			handler(line)
		else:
			pass
			# print 'not match\n %s'% line


NoSubChannel = set(['none', 'luo'])
SameSubChnnel = {
	"mofang": "mongo_if", # Account:22343456 魔方接入时channel只有mofang
}

def getChannelAndSubChannel(account):
	channel = account.channel.split('_')[0]

	if channel == "mofang":
		subChannel = account.channel
	else:
		subChannel = channel if channel in NoSubChannel else account.name.split('_')[0]

	subChannel = SameSubChnnel.get(subChannel, subChannel)
	return channel, subChannel

def getSubchannelByChannel(channel):
	return channel