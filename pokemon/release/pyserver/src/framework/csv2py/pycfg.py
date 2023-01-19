﻿#-*- coding=utf-8 -*-
# csv2py
# 生成py的配置
'''
csv2py config
'''

from datetime import datetime

SRC_PATH = '../../config/game/'
SRC_FILE_LIST = None
LUA_FILE_NAME = 'csv.py'
LUA_MODULE_NAME = 'csv'
PY_NAMETUPLE = False
FOR_LUA = False
LANGUAGE = None

LUA_NIL_VALUE = 'None'
LUA_TRUE_VALUE = 'True'
LUA_FALSE_VALUE = 'False'
LUA_ARRAY_FUNC = lambda array: '(%s,)' % ', '.join(array) if len(array) > 0 else ()
LUA_MAP_KV_FUNC = lambda k, v: '%s : %s' % (k, v)
LUA_MAP_FUNC = lambda values: '{%s}' % (', '.join(values))
LUA_ELEM_KV_FUNC = lambda key, value: "'%s' : %s" % (key, value)
LUA_ROW_FUNC = lambda row, elems: "\t%s : {\r\n\t\t%s\r\n\t}" % (row, ',\r\n\t\t'.join(elems))
LUA_DIR_FUNC = lambda dirName, fileName: "%s['%s']" % (dirName, fileName)
LUA_CSV_FUNC = lambda dirs: '%s["%s"]' % (dirs[0], '"]["'.join(dirs[1:]))
LUA_MODULE_FUNC = lambda name, data, defElems: '''%s = {
%s,
	'__default' : { 
		%s
	}
}
''' % (name, ',\r\n'.join(data), ',\r\n\t\t\t'.join(defElems))
LUA_HEAD_SRC = """#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# auto generated by csv2py
# date: %s
#
# DON'T EDIT THIS FILE !!!
#
""" % datetime.now()
LUA_OTHER_SRC = '''
'''
LUA_OTHER_SRC2 = ""

IGNORE_FILES = []
IGNORE_KEYS = []
