#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Enable Gevent monkey patch
'''

GeventEnable = False

if not GeventEnable:
	from gevent.monkey import patch_all
	patch_all()
	print "it's enable gevent.monkey.patch_all."
	GeventEnable = True

