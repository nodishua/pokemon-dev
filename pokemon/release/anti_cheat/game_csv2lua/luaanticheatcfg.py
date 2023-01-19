﻿#-*- coding=utf-8 -*-
# csv2lua
# 生成lua的配置
'''
csv2lua anti-cheat config
'''

SRC_PATH = '../game_config/'
SRC_FILE_LIST = None
LUA_FILE_NAME = './config/csv.lua'
LUA_MODULE_NAME = 'csv'
PY_NAMETUPLE = False
FOR_LUA = True
LANGUAGE = None

LUA_NIL_VALUE = 'nil'
LUA_TRUE_VALUE = 'true'
LUA_FALSE_VALUE = 'false'
LUA_ARRAY_FUNC = lambda array: '{%s}' % ', '.join(array)
LUA_MAP_KV_FUNC = lambda k, v: '[%s] = %s' % (k, v)
LUA_MAP_FUNC = lambda values: '{%s, __size = %d}' % (', '.join(values), len(values)) if len(values) > 0 else '{__size = 0}'
LUA_ELEM_KV_FUNC = lambda key, value: "%s = %s" % (key, value)
LUA_ROW_FUNC = lambda row, elems: "\t[%s] = {\r\n\t\t%s\r\n\t}" % (row, ',\r\n\t\t'.join(elems))
LUA_DIR_FUNC = lambda dirName, fileName: "%s['%s']" % (dirName, fileName)
LUA_CSV_FUNC = lambda dirs: ".".join(dirs)
def LUA_MODULE_FUNC(name, data, defElems):
	content = ',\r\n'.join(data)
	if len(content) > 0:
		content += ',\r\n'
	return '''%s = {
%s
	__size = %d,
	__default = {
		__index = {
			%s
		}
	}
}
''' % (name, content, len(data), ',\r\n\t\t\t'.join(defElems))
def LUA_MODULE_MULTIPLE_FUNC(name, data, defElems):
	N = 10000
	data2 = data[N:]
	data2holder = ['%s= 0' % x.split('=')[0] for x in data2]
	content = ',\r\n'.join(data[:N] + data2holder)
	if len(content) > 0:
		content += ',\r\n'
	src1 = '''%s = {
%s
	__size = %d,
	__default = {
		__index = {
			%s
		}
	}
}
''' % (name, content, len(data), ',\r\n\t\t\t'.join(defElems))
	src2 = '''
(function()
	local csv = %s
%s
end)()
''' % (name, '\r\n'.join(['csv%s' % x for x in data2]))
	return src1 + src2
LUA_HEAD_SRC = """--
-- auto generated by csv2lua
-- date: 
--
-- DON'T EDIT THIS FILE !!!
--
"""
LUA_OTHER_SRC = '''
local function _setDefalutMeta(t)
	local strsub = string.sub
	for k, v in pairs(t) do
		if type(k) == 'string' and type(v) == 'table' then
			if strsub(k, 1, 2) ~= '__' then
				-- print (k,v)
				_setDefalutMeta(v)
			end
		elseif t.__default and type(k) == 'number' and type(v) == 'table' then
			setmetatable(v, t.__default)
		end
	end
end
'''
LUA_OTHER_SRC2 = '''
_setDefalutMeta(csv)
'''
IGNORE_FILES = []
IGNORE_KEYS = []