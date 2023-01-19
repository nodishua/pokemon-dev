#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

def channelOrderID(channel, orderID):
	return '%s_%s' % (channel, orderID)

def getChannel(order):
	if order.find('_') > 0:
		return order.split('_')[0]
	return None

def getOrderID(order):
	if order.find('_') > 0:
		return order.split('_')[1]
	return None