#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import
import framework.patch
from framework import nowtime_t as raw_nowtime_t

def patch_framework():
	framework.patch.patch_module('game.session', 'framework', [
		('nowtime_t', 'nowtime_t'),
		('nowdate_t', 'nowdate_t'),
		('nowdatetime_t', 'nowdatetime_t'),
	])


patch_framework()

import framework
import game.session
from framework.log import logger

if raw_nowtime_t != framework.nowtime_t and game.session.nowtime_t == framework.nowtime_t:
	logger.info('patch_framework ok !')
else:
	logger.warning('raw_nowtime_t %s' % raw_nowtime_t)
	logger.warning('framework.nowtime_t %s' % framework.nowtime_t)
	logger.warning('game.session.nowtime_t %s' % game.session.nowtime_t)
	raise EnvironmentError('patch_framework error !')
