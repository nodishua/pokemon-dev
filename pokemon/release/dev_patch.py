#!/usr/bin/python
# -*- coding: utf-8 -*-

'''
Copyright (c) 2014 YouMi Information Technology Inc.

use for svn developing
'''

import os
import sys

reload(sys)
sys.setdefaultencoding("utf-8")

# inject shuma path to sys.path
# when shuma not be installed by egg(ex. developing in svn)
if os.path.isdir('src'):
	print 'It is release mode!'
	sys.path.insert(1, os.path.join(os.getcwd(), 'src'))
	
	import framework
	# __dev__状态下会自动更新svn，然后重新读取csv配置
	#framework.__dev__ = True
	framework.__dev_config__ = './config_dev/'
	# framework.__dev_config__ = './config/'
	# 语言版本
	framework.__language__ = 'cn'

framework.init()
