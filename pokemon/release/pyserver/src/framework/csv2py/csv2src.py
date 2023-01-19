#-*- coding=utf-8 -*-
# csv2lua
# 递归扫描SRC_PATH目录，读取全部csv文件，生成lua
# csv路径名去掉.csv后缀后，将分隔符替换为.，即为lua table变量名
# 如bullet\fire.csv -> bullet.fire = {...}

# CSV 规范
# 1 开头是不留空，以行为单位。
# 2 可含或不含列名，含列名则居文件第一行。
# 3 一行数据不跨行，无空行。
# 4 以半角逗号（即,）作分隔符，列为空也要表达其存在。
# 5 列内容如存在半角逗号（即,）则用半角引号（即','）将该字段值包含起来。
# 6 列内容如存在半角引号（即"）则应替换成半角双引号（""）转义，并用半角引号（即""）将该字段值包含起来。
# 7 文件读写时引号，逗号操作规则互逆。
# 8 内码格式不限，可为 ASCII、Unicode 或者其他。
# 9 不支持特殊字符

import os
import re
import uuid
import xlrd
import shutil
import traceback
import platform
import codecs
from datetime import *
# from luacfg import *

import rule

USED_LANGUAGE = ['tw', 'en', 'vn', 'th', 'kr']
MODIFY_FILENAME = "LastModifyList.txt"
TABLE_SLIM_REDUNDANCY = True # lua table冗余优化， FOR_LUA为真时可开启
VALUE_CROP = True # 单元格内容根据rule进行裁剪

#####################################
# 全局配置
LUA_BOOL = 1
LUA_NUM = 2
LUA_STRING = 3
LUA_ARRAY = 4
LUA_MAP = 5
LUA_CSV = 6
LUA_NIL = 7

# 即使配表ID重复，也不重新生成配表
IGNORE_REPEAT_ID = False
# IGNORE_REPEAT_ID = True


#####################################
# 运行时全局变量
g_luaTableMap = {}
g_luaFileTableCache = {} # {txt: [uuid, src, cnt, replace_cnt]}
g_luaFileTableUUIDMap = {} # {uuid: txt}
g_UUID = 0
g_makeDeep = 0
g_luaTypeString = ["", "LUA_BOOL", "LUA_NUM", "LUA_STRING", "LUA_ARRAY", "LUA_MAP", "LUA_CSV", "LUA_NIL"]

#####################################

# 打印用
def utf2local(s):
	if platform.system() == 'Windows':
		return s.decode('utf8').encode('gbk')
	return s

# 比较用
def utf2gbk(s):
	return s.decode('utf8').encode('gbk')

# 打印用
def u2local(s):
	if not isinstance(s, unicode):
		s = s.decode('utf8')
	if platform.system() == 'Windows':
		return s.encode('gbk')
	return s.encode('utf8')

def u2utf8(s):
	if not isinstance(s, unicode):
		return s
	return s.encode('utf8')

def excepStr(fileName, row, col, sLine, sCol, id=None, field=None, reason=None):
	return utf2local("异常：%s (%d, %d)\r\n异常行：%s%s\r\n异常列：%s%s\r\n异常原因：%s\r\n" % (fileName, row, col, " 【%s】 " % u2utf8(id) if id else "", sLine, " 【%s】 " % u2utf8(field) if field else "", u2utf8(sCol), u2utf8(reason) if reason else ""))

# 注意没更改过的配表，不能产生diff
def uuidname():
	global g_UUID
	g_UUID += 1
	return '__predefine_t__[%d]' % g_UUID
	# k = '__' + str(uuid.uuid4()).replace('-', '_')
	# while k in g_luaFileTableUUIDMap:
	# 	k = '__' + str(uuid.uuid4()).replace('-', '_')
	# return k

def strSys2User(s):
	s = s.strip()
	# remove system "
	if s[0] == s[-1] == '"':
		s = s[1:-1]
	# system escape "" -> "
	return s.replace('""', '"')

def strUser2Sys(s):
	s = s.replace('"', '""')
	return '"%s"' % s

def autoUser2Sys(s):
	if len(s) > 1 and s[0] == s[-1] == "'":
		return strUser2Sys(s)
	elif len(s) > 0 and s[0] == s[-1] == '"':
		return strUser2Sys(s)
	return s

def isCompatibility(t, castType):
	# LUA_BOOL = 1
	# LUA_NUM = 2
	# -> ok
	# LUA_STRING = 3
	# -> no
	# LUA_ARRAY = 4
	# LUA_MAP = 5
	# LUA_CSV = 6
	# LUA_NIL = 7
	if t == castType:
		return True
	if t <= LUA_STRING and castType == LUA_STRING:
		return True
	if t == LUA_STRING and castType == LUA_CSV:
		return True
	return False

def isBool(s):
	return s in ('true', 'false', 'True', 'False', 'TRUE', 'FALSE')

def isInt(s):
	try:
		int(s)
		return True
	except Exception, e:
		# print e
		return False

def isFloat(s):
	try:
		float(s)
		return True
	except Exception, e:
		# print e
		return False

def isNumber(s):
	return isInt(s) or isFloat(s)

def isString(s):
	if len(s) == 0:
		return False
	# 用户强制设定字符串
	if s[:3] == '"""' and s.count('"') % 2 == 0 and s[-3:] == '"""':
		return True
	if s[:2] == '""' and s.count('"') % 2 == 0 and s[-2:] == '""':
		return True
	if s[0] == "'" and s.count("'") == 2 and s[-1] == "'":
		return True
	# 系统字符串标示，还需要后续检查
	return False

	# return (s[0] == '"' and s.count('"') % 2 == 0 and s[-1] == '"')\
		# or (s[0] == "'" and s.count("'") == 2 and s[-1] == "'")

def isCsv(s):
	return s.endswith(".csv") or s.endswith(".xls") or s.endswith(".xlsx")

def isNil(s):
	if len(s) == 0:
		return True

'''
Array:
<item1;item2;item3;item4>
item支持嵌套
'''
def isArray(s):
	s = strSys2User(s)
	return s[0] == '<' and s[-1] == '>'

'''
Map:
{key=value;key=value}
key: int, string
value支持嵌套

1 = 222 ;aaa =' 333 ';bbb= 'x;x;x'
'''
def isMap(s):
	s = strSys2User(s)
	return s[0] == '{' and s[-1] == '}'

def whatType(s):
	s = s.strip()
	if isNil(s):
		return LUA_NIL
	elif isCsv(s):
		return LUA_CSV
	elif isString(s):
		return LUA_STRING
	elif isBool(s):
		return LUA_BOOL
	elif isNumber(s):
		return LUA_NUM
	elif isMap(s):
		return LUA_MAP
	elif isArray(s):
		return LUA_ARRAY
	return LUA_STRING

def showTypeString(luaType):
	return '%d(%s)' % (luaType, g_luaTypeString[luaType])

def readCsv(fileName):
	fp = open(fileName, 'rb')
	lines = fp.readlines()
	fp.close()

	isBOMUTF8 = lines[0][:3] == codecs.BOM_UTF8
	if isBOMUTF8:
		lines[0] = lines[0][3:]
	ret = []
	for x in lines:
		if isBOMUTF8:
			ret.append(x.decode('utf8'))
		else:
			ret.append(x.decode('gbk'))
	return ret

def readXls(fileName):
	book = xlrd.open_workbook(fileName)
	sheet = book.sheet_by_index(0)
	lines = []
	index = 1
	for rx in xrange(sheet.nrows):
		line = []
		for cy in xrange(sheet.ncols):
			cell = sheet.cell(rx, cy)
			val = cell.value
			if cell.ctype in (2, 3):
				# XL_CELL_NUMBER	2	float
				# XL_CELL_DATE	3	float
				if int(val) == val:
					val = unicode(int(val))
				else:
					val = unicode(val)
			elif cell.ctype in (0, 1):
				# XL_CELL_EMPTY	0	empty string u''
				# XL_CELL_TEXT	1	a Unicode string
				pass
			elif cell.ctype == 4:
				# XL_CELL_BOOLEAN	4	int; 1 means TRUE, 0 means FALSE
				val = "TRUE" if val == 1 else "FALSE"
			else:
				# XL_CELL_ERROR	5	int representing internal Excel codes; for a text representation, refer to the supplied dictionary error_text_from_code
				# XL_CELL_BLANK	6	empty string u''. Note: this type will appear only when open_workbook(..., formatting_info=True) is used.
				raise Exception('%s xls %d:%d cell type %s no handle %s' % (fileName, rx, cy, showTypeString(cell.ctype), val))
			ret = val.strip()
			retType = whatType(ret)
			# 前3行不处理，以下结构转换处理成csv存储结构
			if index > 3 and (retType == LUA_STRING or retType == LUA_ARRAY or retType == LUA_MAP):
				ret = ret.replace('"', '""')
				ret = '"%s"' % ret
			line.append(ret)
		lines.append(line)
		index = index + 1
	return lines

def splitLine(line):
	# return [x.strip() for x in line.split(',')]
	ret = []
	tmp = ''
	strb = False
	ignore = False
	for i in xrange(len(line)):
		c = line[i]
		if ignore:
			tmp += c
			ignore = False
			continue

		if c == ',':
			if not strb:
				ret.append(tmp)
				tmp = ''
				continue
		elif c == '"':
			if strb:
				if i + 1 < len(line) and line[i+1] == '"':
					ignore = True
				else:
					strb = False
			else:
				strb = True

		tmp += c
	ret.append(tmp)
	return [x.strip() for x in ret]

def parseCsv(fileName, keys, vars, defs, lines):
	# 第一行为变量名（必须有）
	varList = [x.strip() for x in (vars if isinstance(vars, list) else vars.split(','))]

	# 第二行为默认值
	defList = [x.strip() for x in (defs if isinstance(defs, list) else defs.split(','))]

	# 第二（或三）行为属性名，忽略空的列
	keyList = [x.strip() for x in (keys if isinstance(keys, list) else keys.split(','))]

	# keys和vars长度必须一致，取小的值
	if len(varList) != len(keyList):
		for i in range(max(len(varList), len(keyList))):
			print varList[i], keyList[i].decode('gbk')
		print excepStr(fileName, 0, 0, "", "", reason=u"第一行与第三行长度不一致")
		raise Exception("varList %d, keyList %d, there length must be equal!" % (len(varList), len(keyList)))

	varFilter = None
	for ffilter, vfilter in IGNORE_KEYS:
		if re.search(ffilter, fileName):
			varFilter = vfilter

	varColMap = {var: i for i, var in enumerate(varList)}
	# 忽略变量名以下划线开始的列（比如_comment，只是注释功能）
	# 忽略IGNORE_KEYS中定义
	ignoreList = [False] * len(varList)
	l10nCheckedList = [False] * len(varList)
	for i in xrange(1, len(varList)):
		if len(varList[i]) == 0 or len(keyList[i]) == 0:
			print '==============='
			print i, keyList
			raise Exception("column [%d] %s is invalid!" % (i, keyList[i]))
		if ignoreList[i]:
			continue
		if varList[i][0] == '_':
			ignoreList[i] = True
			continue
		if varFilter and re.search(varFilter, varList[i]):
			# print fileName, varList[i], utf2local('字段忽略')
			ignoreList[i] = True
		# if no configuration, no check
		if LANGUAGE and (fileName.find("StringCfg.xls") == -1 or fileName.find("StringCfg.xlsx") == -1):
			# ignore l10n
			if l10nCheckedList[i]:
				continue
			ignoreList[i] = True
			for x in USED_LANGUAGE:
				l10nVar = '%s_%s' % (varList[i], x)
				if l10nVar in varColMap:
					ignoreList[varColMap[l10nVar]] = True
					l10nCheckedList[varColMap[l10nVar]] = True
			# because cn first
			if LANGUAGE == 'cn':
				ignoreList[i] = False
			else:
				l10nVar = '%s_%s' % (varList[i], LANGUAGE)
				if l10nVar in varColMap:
					ignoreList[varColMap[l10nVar]] = False
					l10nCheckedList[varColMap[l10nVar]] = True
					# 有多语言版本则直接替换key名字
					varList[varColMap[l10nVar]] = varList[i]
				else:
					ignoreList[i] = False

	# for i in xrange(1, len(varList)):
	# 	if ignoreList[i]:
	# 		print fileName, varList[i], utf2local('字段被忽略')

	defList = defList[:len(varList)]
	defList = [None if len(x) == 0 else x for x in defList]
	if len(varList) != len(defList):
		defList += [None] * (len(varList) - len(defList))

	# 忽略第一列为空的行
	validLines = []
	for line in lines:
		if isinstance(line, list):
			valueList = line
		else:
			valueList = splitLine(line)
		if len(valueList[0]) == 0:
			continue
		validLines.append(valueList)

	# 组装字符串矩阵
	validMat = [[None for col in xrange(len(keyList))] for row in xrange(len(validLines))]
	for row in xrange(len(validLines)):
		for col in xrange(len(keyList)):
			if col >= len(validLines[row]):
				break
			if ignoreList[col]:
				continue
			# 空串设置为None，如果真需要空串，要使用LUA_STRING方式定义''
			if len(validLines[row][col]) == 0:
				continue
			validMat[row][col] = validLines[row][col]

	# 去除注释列
	for i in xrange(len(ignoreList) - 1, 0, -1):
		if not ignoreList[i]:
			continue
		# print 'ignore', varList[i]
		del keyList[i]
		del varList[i]
		del defList[i]
		for row in xrange(len(validMat)):
			del validMat[row][i]

	# 判断列数据类型
	for col in xrange(len(keyList)):
		luaType, defType = 0, 0
		# 先获取默认值的lua type
		if (col != 0) and (not defList[col] is None):
			defType = whatType(defList[col])
			luaType = defType
		for row in xrange(len(validMat)):
			if validMat[row][col] == None:
				continue
			if validMat[row][col] == defList[col]:
				# 字符串相同，直接使用默认值，减少配置生成项
				validMat[row][col] = None
				continue
			elemType = whatType(validMat[row][col])
			luaType = max(luaType, elemType)

		# 该列有默认值的情况，严格判断值类型
		if defType != 0:
			for row in xrange(len(validMat)):
				if validMat[row][col] == None:
					continue
				elemType = whatType(validMat[row][col])
				if not isCompatibility(elemType, defType):
					print '!!! ', validMat[row][col], showTypeString(elemType) , '->', defList[col], showTypeString(defType)
					print excepStr(fileName, row, col, "", validMat[row][col], id=validMat[row][0], field=varList[col], reason=u"与默认值类型不匹配")
					raise Exception("elem type not compatible with default type")

		# 空列忽略
		# if luaType == 0:
		# 	raise Exception('column [%d] %s can not be recognize!' % (col, keyList[col]))
		keyList[col] = [keyList[col], varList[col], luaType, defList[col]]

	# 第一列不需要变量名和默认值
	luaType = keyList[0][2]
	keyList[0] = [keyList[0][0], None, luaType, None]

	# 第一列只能是整数
	if not keyList[0][2] in (LUA_NUM,):
		raise Exception('first column must be number, now is %d!' % keyList[0][2])

	# 检查是否有重复ID
	hasRepeat = False
	idSet = set()
	for row in xrange(len(validMat)):
		id = validMat[row][0]
		if id in idSet:
			print '!!!', 'row [%d] has duplicated ID %s!' % (row, id), fileName
			print excepStr(fileName, row, 0, "", validMat[row][0], id=validMat[row][0], field="ID", reason=u"ID重复")
			hasRepeat = True
		idSet.add(id)

	# debug
	# for i in keyList:
	# 	print 'keyList', i[0], i[1], i[2], i[3]

	return keyList, validMat, defList, hasRepeat

# s是原始串
def autoMake(s):
	# print 'autoMake',repr(s)
	luaType = whatType(s)
	return makeElem(luaType, s)

DELIM_MATCH = {'"':'"', "'":"'", '<':'>', '{':'}'}
ESCAP_MATCH = ('"', "'")
RECUR_MATCH = ('<', '{')

def splitToArrayByDelim(s):
	s = strSys2User(s)[1:-1]
	delim, part, array = [], '', []
	for i in s:
		part += i
		# print i, delim, part
		if len(delim) > 0:
			if i == delim[-1]:
				del delim[-1]
			elif delim[-1] in ESCAP_MATCH:
				# 字符串中会有<和{的可能，配置了公式应当做字符串处理
				pass
			elif i in RECUR_MATCH:
				delim.append(DELIM_MATCH[i])
		elif i in DELIM_MATCH:
			delim.append(DELIM_MATCH[i])
		elif i == ';':
			array.append(part[:-1])
			part = ''
	if len(part) > 0:
		array.append(part)
	return array

def makeArray(s):
	# print 'makeArray', s
	global g_makeDeep
	g_makeDeep += 1
	if FOR_LUA and TABLE_SLIM_REDUNDANCY and g_makeDeep == 1 and s in g_luaFileTableCache:
		g_makeDeep -= 1
		g_luaFileTableCache[s][2] += 1
		return g_luaFileTableCache[s][0]

	array = splitToArrayByDelim(s)
	array = [autoMake(autoUser2Sys(x)) for x in array]
	# array中间为空的需要保留nil
	array = [LUA_NIL_VALUE if x is None else x for x in array]
	ret = LUA_ARRAY_FUNC(array)
	# print ret
	g_makeDeep -= 1
	if FOR_LUA and TABLE_SLIM_REDUNDANCY and g_makeDeep == 0:
		key = uuidname()
		g_luaFileTableCache[s] = [key, ret, 1, 0]
		g_luaFileTableUUIDMap[key] = s
		return g_luaFileTableCache[s][0]
	else:
		return ret


def makeMap(s):
	# print 'makeMap', s
	global g_makeDeep
	g_makeDeep += 1
	if FOR_LUA and TABLE_SLIM_REDUNDANCY and g_makeDeep == 1 and s in g_luaFileTableCache:
		g_makeDeep -= 1
		g_luaFileTableCache[s][2] += 1
		return g_luaFileTableCache[s][0]

	array = splitToArrayByDelim(s)

	mapp = {}
	cnt = 0
	for i in array:
		if len(i.strip()) == 0:
			continue
		pos = i.find('=')
		if pos == -1:
			raise Exception('map k-v must be split by "="!')
		k, v = i[:pos], i[pos+1:]
		kType = whatType(k)
		if (kType != LUA_NUM) and (kType != LUA_STRING):
			raise Exception('key must be integer or string!')
		if len(v.strip()) == 0:
			raise Exception('value was empty!')
		k, v = autoMake(autoUser2Sys(k)), autoMake(autoUser2Sys(v))
		if v is None:
			continue
		if k in mapp:
			raise Exception('map key %s deuplicated!' % k)
		mapp[k] = LUA_MAP_KV_FUNC(k, v)
		cnt += 1

	# if 0 == len(mapp):
	# 	return None

	if cnt != len(mapp):
		raise Exception('map key deuplicated!')

	ret = LUA_MAP_FUNC(mapp.values())
	# print ret
	g_makeDeep -= 1
	if FOR_LUA and TABLE_SLIM_REDUNDANCY and g_makeDeep == 0:
		key = uuidname()
		g_luaFileTableCache[s] = [key, ret, 1, 0]
		g_luaFileTableUUIDMap[key] = s
		return g_luaFileTableCache[s][0]
	else:
		return ret


def splitFilePath(filePath):
	filePath = os.path.splitdrive(filePath)[1]
	(filePath, fileName) = os.path.split(filePath)
	dirList = []
	while len(filePath) > 0:
		(filePPath, dirName) = os.path.split(filePath)
		if filePPath == filePath:
			break
		filePath = filePPath
		dirList.append(dirName)
	dirList.reverse()
	return dirList, fileName

# 现在只有csv配表内LUA_CSV数值是相对目录
# 生成文件时是完整路径，g_luaTableMap遇到完整路径时认为是生成文件
# @return csv路径前缀构造，csv路径，csv引用路径
def makeCsvVar(fileName, isRel = False):
	fileName = fileName.replace('\\', '/')
	fileName = os.path.normpath(fileName)
	if not isRel:
		fileName = os.path.relpath(fileName, SRC_PATH)
	dirList, fileName = splitFilePath(fileName)
	if fileName.endswith('.xlsx'):
		fileName = fileName[:-5]
	else:
		fileName = fileName[:-4] # delete .csv

	if len(dirList) == 0:
		g_luaTableMap[LUA_MODULE_NAME + "." + fileName] = True
		return '', LUA_DIR_FUNC(LUA_MODULE_NAME, fileName), LUA_MODULE_NAME + "." + fileName

	varPerList = []
	dirList.append(fileName)
	varName = LUA_MODULE_NAME
	luaVarPath = LUA_MODULE_NAME
	for i in xrange(0, len(dirList)):
		if luaVarPath not in g_luaTableMap:
			varPerList.append("%s = {}\r\n" % varName)
			if not isRel:
				g_luaTableMap[luaVarPath] = True
		varName = LUA_DIR_FUNC(varName, dirList[i])
		# varName = varName + "['%s']" % dirList[i]
		luaVarPath = luaVarPath + '.' + dirList[i]
	return "".join(varPerList), varName, LUA_CSV_FUNC([LUA_MODULE_NAME] + dirList)

def makeDef(keyList, defList):
	elem = []
	defs = [None for i in defList]
	idx = 0
	for keyT in keyList[1:]:
		name, varName, luaType, defVar = keyT
		idx += 1

		if PY_NAMETUPLE:
			if defVar is None:
				elem.append(LUA_ELEM_KV_FUNC(varName, None))
				continue
			value = makeElem(luaType, defVar)
			elem.append(LUA_ELEM_KV_FUNC(varName, value))
			defs[idx] = value

		else:
			if defVar is None:
				continue
			value = makeElem(luaType, defVar)

			if value is None:
				continue
			elem.append(LUA_ELEM_KV_FUNC(varName, value))
			defs[idx] = value
	# elem = ',\r\n\t\t\t'.join(elem)
	return elem, defs

def makeString(s):
	s = s.strip()
	# remove system "
	if s[0] == s[-1] == '"':
		s = s[1:-1]
	# system escape "" -> "
	s = s.replace('""', '"')
	if len(s) == 0:
		return "''"
	# remove user " and '
	if s[0] == s[-1] == '"':
		s = s[1:-1]
	elif len(s) > 1 and s[0] == s[-1] == "'":
		s = s[1:-1]
	return "'%s'" % s.replace("'", "\\'")

def makeElem(luaType, strValue):
	strValue = strValue.strip()
	# print 'makeElem', luaType, strValue
	ret = None
	if luaType == LUA_NIL:
		return None
	elif luaType == LUA_BOOL:
		if strValue in ('true', 'True', 'TRUE'):
			ret = LUA_TRUE_VALUE
		else:
			ret = LUA_FALSE_VALUE
	elif luaType == LUA_NUM:
		ret = strValue
	elif luaType == LUA_STRING:
		# " -> """"
		# ' -> '
		# "" -> """"""
		# '' -> ''
		# '" -> "'"""
		# "' -> """'"

		# csv """" -> str " -> val '"'
		# csv """""" -> str "" -> val ''
		# csv """1    2""" -> str "1    2" -> val '1    2'
		# csv """1    2""3" -> str "1    2"3 -> val '"1    2"3'
		ret = makeString(strValue)

		# strValue = strValue.strip()
		# if strValue[0] == '"' and strValue[-1] == '"':
		# 	strValue = strValue[1:-1].replace('""', '"')
		# 	if len(strValue) > 1 and strValue[0] == '"' and strValue[-1] == '"':
		# 		ret = "'%s'" % strValue[1:-1].replace("'", "\\'")
		# 	else:
		# 		ret = "'%s'" % strValue.replace("'", "\\'")
		# elif len(strValue) > 1 and strValue[0] == "'" and strValue[-1] == "'":
		# 	ret = "'%s'" % strValue[1:-1].replace("'", "\\'")
		# else:
		# 	ret = "'%s'" % strValue.replace("'", "\\'")

	elif luaType == LUA_CSV:
		_, _, value = makeCsvVar(strValue, True)
		# csv 引用使用字符串，后期在lua延迟调用
		ret = "'%s'" % value
		# print strValue, ret
	elif luaType == LUA_ARRAY:
		ret = makeArray(strValue)
	elif luaType == LUA_MAP:
		ret = makeMap(strValue)
	else:
		raise Exception('luaType %s is invalid!' % showTypeString(luaType))

	# print '->', ret

	# if ret is None:
	# 	raise Exception('makeElem(%d, "%s") is error!' % (luaType, strValue))
	return ret

def replaceUUID(csvName, data, forceReplace = None):
# 	preMT = '''
# local __mt = {
# 	__newindex = function(t, k, v)
# 		if type(k) == "string" and string.sub(k, 1, 1) == '_' then
# 			rawset(t, k, v)
# 		else
# 			local str = string.format("!!! ''' + csvName.replace('\\', '/') + ''' __predefine_t__ newindex: key = %s, val = %s", k, v)
# 			error(str)
# 		end
# 	end
# }
# '''
	preMT = ''

	predefine = ''
	if FOR_LUA and TABLE_SLIM_REDUNDANCY:
		predefine = []
		for i, elem in enumerate(data):
			# find data index
			index = '"default"'
			m = re.findall('\[([0-9]*)\] = ', elem)
			if m:
				index = m[0]
			else:
				if re.findall('\[(-[0-9]*)\] = ', elem):
					print "check csvid:", csvName, elem

			p = 0
			while True:
				p = elem.find('__predefine_t__', p)
				if p < 0:
					break
				# find data key
				key = re.findall('(\w*) = __predefine_t__', elem)[0]

				p2 = elem.find(']', p)
				uuid = elem[p:p2+1] #__predefine_t__[5]
				p = p2
				s = g_luaFileTableUUIDMap[uuid]
				_, src, cnt, replace = g_luaFileTableCache[s]
				# table只有1次的，直接塞进去
				# print uuid, cnt
				if cnt == 1 or forceReplace == True:
					elem = elem.replace(uuid, src)
					g_luaFileTableCache[s][-1] += 1
					p -= len(uuid)

				else:
					dataKey = '__data_t__%s' % key
					if dataKey not in g_dataMap:
						g_dataMap[dataKey] = {}
					g_dataMap[dataKey][index] = uuid

					elem = elem.replace(uuid, '%s[%s]' % (dataKey, index), 1)
					# 多次的添加注释
					p3 = elem.find('\r\n', p) + 2
					if p3 > p:
						flag = '\t\t-- %s\r\n\t' % src
						elem = elem[:p3] + flag + elem[p3+1:]
					else:
						flag = '\t--[[ %s]]' % src
						elem += flag
					p = p3 + len(flag)

			data[i] = elem

		seq = sorted(g_luaFileTableUUIDMap.keys(), key=lambda s: int(s[s.find('[')+1:s.find(']')]))
		for uuid in seq:
			s = g_luaFileTableUUIDMap[uuid]
			_, src, cnt, replace = g_luaFileTableCache[s]
			if cnt > 1:
				# predefine.append('\r\n\t' + LUA_ELEM_KV_FUNC(uuid[15:], "setmetatable(" + src + ", __mt)"))
				predefine.append('\r\n\t' + LUA_ELEM_KV_FUNC(uuid[15:], src))

		dataT = ""
		global g_dataMapLen
		for dataMap in g_dataMap.items():
			key = dataMap[0]
			t = []
			for v in dataMap[1].items():
				t.append('[%s] = %s' % (v[0], v[1]))
			if g_dataMapLen + len(dataMap[1]) > 5000:
				# print 'create %s function' % key, csvName
				dataT += 'local %s = {}\r\n' % key + '(function()\r\n\tlocal t = %s\r\n\tt' % key +'\r\n\tt'.join(t) + '\r\nend)()\r\n'
			elif len(dataMap[1]) > 0:
				dataT += 'local %s = {\r\n\t' % key +',\r\n\t'.join(t) + "\r\n}\r\n"
				g_dataMapLen += len(dataMap[1])

		predefine = preMT + 'local __predefine_t__ = ' + LUA_MAP_FUNC(predefine) + '\r\n' + dataT

	predefine += '\r\n'
	return predefine, data

def relpath(fileName):
	fileName = fileName.replace('\\', '/')
	fileName = os.path.normpath(fileName)
	fileName = os.path.relpath(fileName, SRC_PATH)
	if fileName.endswith('.xlsx'):
		fileName = fileName[:-5]
	else:
		fileName = fileName[:-4] # delete .csv
	return fileName

def currentRowInvalid(lang, value, default):
	if not value:
		value = default
	return not re.search("%s[;>]" % lang, value)

def makeInvalidList(name, keyList, strMat, defList):
	col = -1
	for i, (_, var, _, _) in enumerate(keyList):
		if var == "languages":
			col = i
			break
	if col <= 0:
		return
	ids = set()
	for row in xrange(len(strMat)):
		if currentRowInvalid(LANGUAGE, strMat[row][col], defList[col]):
			csvid = strMat[row][0]
			ids.add(csvid)
	if name == 'cards.csv':
		rule.setInvalidCards(ids)
	elif name == 'fragments.csv':
		rule.setInvalidFrags(ids)

	# 抽卡过滤
	col = -1
	for i, (_, var, _, _) in enumerate(keyList):
		if var == "drawlanguages":
			col = i
			break
	if col <= 0:
		return
	ids = set()
	for row in xrange(len(strMat)):
		if currentRowInvalid(LANGUAGE, strMat[row][col], defList[col]):
			csvid = strMat[row][0]
			ids.add(csvid)
	if name == 'cards.csv':
		rule.setInvalidDrawCards(ids)
	elif name == 'fragments.csv':
		rule.setInvalidDrawFrags(ids)

def value2elem(luaType, value, defaultValue):
	skiped = False
	if PY_NAMETUPLE:
		if value is None:
			value = None
		else:
			# array和map可能返回None，相当于LUA_NIL
			value = makeElem(luaType, value)
			# 等于默认值时优化
			if value == defaultValue:
				value = None
	else:
		# 无数据，并且无默认值，跳过生成
		if (value is None) and (defaultValue is None):
			return True, value
		# 没有值
		if value is None:
			return True, value
		# array和map可能返回None，相当于LUA_NIL
		value = makeElem(luaType, value)
		if value is None:
			return True, value
		# 等于默认值时优化
		if value == defaultValue:
			return True, value
	return skiped, value


def makeLua(csvName, keyList, strMat, defList, hasRepeat):
	global g_luaFileTableCache, g_luaFileTableUUIDMap, g_UUID
	g_luaFileTableCache = {}
	g_luaFileTableUUIDMap = {}
	g_UUID = 0

	languageIdx = -1
	if LANGUAGE:
		for i, (_, var, _, _) in enumerate(keyList):
			if var == "languages":
				languageIdx = i
				break
	key, func = rule.getCurrentRowInvalidKeyFunc(relpath(csvName))
	keyidx = -1
	if key:
		for i, (_, var, _, _) in enumerate(keyList):
			if var == key:
				keyidx = i
				break

	# filter 默认值
	if VALUE_CROP:
		for col in xrange(1, len(keyList)):
			value = defList[col]
			value = rule.filterValue(relpath(csvName), keyList[col][1], value)
			defList[col] = value

	varPreName, varName, varPath = makeCsvVar(csvName)
	defElems, defvList = makeDef(keyList, defList)


	data = []
	for row in xrange(len(strMat)):
		elem = []
		elemLine = strMat[row]
		if VALUE_CROP:
			if languageIdx > 0 and relpath(csvName) not in ('cards', 'fragments'):
				# 判断该行是否是有效语言
				if currentRowInvalid(LANGUAGE, elemLine[languageIdx], defList[languageIdx]):
					# if elemLine[languageIdx]:
					# 	print '%s id %s languages not match, got %s' % (csvName, elemLine[0], elemLine[languageIdx])
					# else:
					# 	print '%s id %s languages not match, got %s' % (csvName, elemLine[0], defList[languageIdx])
					continue
			# 判断该行是否有效
			if key > 0:
				if func(key, elemLine[keyidx], defList[keyidx]):
					continue

		try:
			for col in xrange(1, len(keyList)):
				luaType = keyList[col][2]
				value = elemLine[col]
				if VALUE_CROP:
					value = rule.filterValue(relpath(csvName), keyList[col][1], value)
				skiped, value = value2elem(luaType, value, defvList[col])
				if skiped:
					continue
				elem.append(LUA_ELEM_KV_FUNC(keyList[col][1], value))
			luaType = keyList[0][2]
			elem = LUA_ROW_FUNC(makeElem(luaType, elemLine[0]), elem)
			data.append(elem)

		except Exception, e:
			print '!!!', csvName, row, col, elemLine
			print '!!!', elemLine[col]
			print excepStr(csvName, row, col, elemLine, elemLine[col], id=elemLine[0], field=keyList[col][1], reason=str(e))
			raise e

	if len(data) == 0:
		print 'Warning', csvName, utf2local('对应配表数据为空, 语言 %s' % LANGUAGE)

	global g_dataMap # 为了查看diff方便，映射一个表 __data_t__val[idx1] = __predefine_t__[idx2]
	global g_dataMapLen # 记录使用了定义空间的大小
	g_dataMap = {}
	g_dataMapLen = 0
	predefine, defElems = replaceUUID(csvName, defElems)
	predefine, data = replaceUUID(csvName, data)
	namedT = ''
	if PY_NAMETUPLE:
		namedT = LUA_MODULE_NAMETUPLE_FUNC(varName, keyList)

	module = None
	if len(data) + g_dataMapLen > 10000:
		# lua过长jit某个版本会报错，has more than 65536 constants
		if FOR_LUA:
			print utf2local("MULTIPLE：%s" % csvName)
			module = LUA_MODULE_MULTIPLE_FUNC(varName, data, defElems)

	if module is None:
		module = LUA_MODULE_FUNC(varName, data, defElems)

	return predefine + namedT + module, varPath, hasRepeat


def listFiles(rootDir, ext = None):
	list_dirs = os.walk(rootDir)
	list_ret = []
	for root, dirs, files in list_dirs:
		for f in files:
			if not f[0].isalnum():
				print f, utf2local('文件名格式不对，忽略')
				continue
			pf = os.path.join(root, f)
			if not ext is None:
				flag = False
				if isinstance(ext, list):
					flag = True
					for e in ext:
						if f.endswith(e):
							flag = False
							break
				else:
					flag = not f.endswith(ext)
				if flag:
					# print pf, '文件忽略'
					continue
			flag = True
			for reF in IGNORE_FILES:
				if re.search(reF, pf):
					print pf, '文件忽略'
					flag = False
					break
			if flag:
				list_ret.append(pf)
	# 如果是list，有优先级覆盖
	if isinstance(ext, list):
		listD = {}
		priority = {e: i for i, e in enumerate(ext)}
		for filename in list_ret:
			short, nowExt = os.path.splitext(filename)
			if short in listD:
				_, preExt = os.path.splitext(listD[short])
				if priority[nowExt] < priority[preExt]:
					listD[short] = filename
			else:
				listD[short] = filename
		# for i in listD.values():
		# 	if i.endswith('.xls'):
		# 		print 'use xls', i
		# 	elif i.endswith('.xlsx'):
		# 		print 'use xlsx', i
		return listD.values()
	return list_ret

def normalPaths(fileLst, rootDir):
	return [os.path.join(rootDir, i) for i in fileLst]

def getDirFiles(rootDir,module):
	list_dirs = os.listdir(rootDir)
	varPerList = []
	for Dir in list_dirs:
		path1 = os.path.join(rootDir,Dir)
		if os.path.isdir(path1) and path1.endswith(".svn") == False:
			varName = LUA_DIR_FUNC(module, Dir)
			varPerList.append("%s = {}\r\n" % varName)
			varPerList.append(getDirFiles(path1,varName))
	return "".join(varPerList)

def writeSrc(luaSrc):
	if FOR_LUA:
		luaSrc = ['require "%s"' % f for f in luaSrc]
		luaSrc = '\r\n'.join(luaSrc)
	else:
		luaSrc = '\r\n'.join(luaSrc)

	# gbk to utf8
	dirFiles = getDirFiles(SRC_PATH, LUA_MODULE_NAME)
	luaSrc = LUA_HEAD_SRC + LUA_OTHER_SRC + ("%s = {}\r\n" % LUA_MODULE_NAME) + dirFiles + luaSrc + LUA_OTHER_SRC2

	# luaSrc = luaSrc.decode('gbk').encode('utf8')
	luaSrc = luaSrc.encode('utf8')

	fp = open(LUA_FILE_NAME, 'wb')
	fp.write(luaSrc)
	fp.close()

def writeOneSrc(luaSrc, fileName):
	try:
		path = os.path.dirname(fileName)
		if path:
			os.makedirs(path)
	except:
		pass

	# gbk to utf8
	luaSrc = '\r\n'.join(luaSrc)
	luaSrc = LUA_HEAD_SRC + luaSrc
	# luaSrc = luaSrc.decode('gbk').encode('utf8')
	luaSrc = luaSrc.encode('utf8')

	fp = open(fileName, 'wb')
	fp.write(luaSrc)
	fp.close()

def checkModify(fileList):
	# return True, {}

	if not os.path.exists(MODIFY_FILENAME):
		open(MODIFY_FILENAME,"w").close()
	modifyDict = {}
	modifyListFile = open(MODIFY_FILENAME,"r")
	for line in modifyListFile.readlines():
		[key, value] = line.split(",")
		modifyDict[key] = int(value.strip())
	modifyListFile.close()
	hasNewFile = False
	## 有无文件删减，如果有，或者不在windows系统下，则全部重新生成
	for fileName in fileList:
		if not modifyDict.get(fileName):
			hasNewFile = True
	for (k,v) in modifyDict.items():
		if not os.path.exists(k):
			hasNewFile = True
	if platform.system().lower() != "windows":
		hasNewFile = True
	return hasNewFile, modifyDict

def main():
	global g_luaTableMap
	g_luaTableMap = {}
	global VALUE_CROP

	print utf2local('csv2src工作目录：'), os.getcwd()
	print utf2local('csv2src配置源目录：'), SRC_PATH
	print utf2local('csv2src输出文件：'), LUA_FILE_NAME
	print utf2local('csv2src语言：'), LANGUAGE
	if not LANGUAGE:
		VALUE_CROP = False

	fileList = normalPaths(SRC_FILE_LIST, SRC_PATH) if SRC_FILE_LIST else listFiles(SRC_PATH, ['.csv', '.xls', '.xlsx'])
	luaSrc = []
	hasNewFile, modifyDict = checkModify(fileList)
	# 没有文件增删，则只生成修改的文件
	if not hasNewFile:
		fileList = [fileName for fileName in fileList if modifyDict.get(fileName) != int(round(os.path.getmtime(fileName)))]
	else:
		modifyDict.clear()

	# 1. init invalud list
	if VALUE_CROP:
		for name in ['cards.csv', 'fragments.csv']:
			fileName = os.path.join(SRC_PATH, name)
			lines = readCsv(fileName)
			keyList, strMat, defList, hasRepeat = parseCsv(fileName, lines[2], lines[0], lines[1], lines[3:])
			makeInvalidList(name, keyList, strMat, defList)
		fileList = rule.appendRelatedFiles(fileList, SRC_PATH)

	total = len(fileList)
	g_luaTableMap[LUA_MODULE_NAME] = True

	for i, fileName in enumerate(fileList, 1):
		# print '(%d/%d) fileName: %s' % (i, total, fileName)
		if fileName.endswith('.csv'):
			lines = readCsv(fileName)
		else:
			lines = readXls(fileName)

		if len(lines) <= 2:
			continue

		if isinstance(lines[0], list):
			if lines[0][0].strip() != u'变量名':
				print fileName, utf2local('第一行不是“变量名”，文件无法被生成！')
				continue
		else:
			if lines[0].split(',')[0].strip() != u'变量名':
				print fileName, utf2local('第一行不是“变量名”，文件无法被生成！')
				continue

		# 默认值
		beginLine, defs = 2, lines[1]

		try:
			luaCsv, luaPath, hasRepeat = makeLua(fileName, *parseCsv(fileName, lines[beginLine], lines[0], defs, lines[beginLine+1:]))
			# print luaPath
			# print luaCsv
			# dupt = [(t, k, c) for (t, (k, s, c, cc)) in g_luaFileTableCache.items() if c > 1]
			# dupt = sorted(dupt, key=lambda t: t[2])
			# for x in dupt:
			# 	print x

			luaOneSrc = []
			if FOR_LUA:
				luaOneSrc.append(luaCsv)
				# lua使用单文件形式
				tmp = path = os.path.normpath(os.path.dirname(LUA_FILE_NAME))
				paths = []
				while tmp:
					tmp, d = os.path.split(tmp)
					paths.append(d)
				luaSrc.append('.'.join(paths) + luaPath[3:])
				luaPath = luaPath.replace('.', '/')[4:] + '.lua'
				luaPath = os.path.join(path, luaPath)
				writeOneSrc(luaOneSrc, luaPath)

			# no for lua
			else:
				luaSrc.append(luaCsv)

			# print fileName, utf2local('文件生成完毕.')
			if not hasRepeat or IGNORE_REPEAT_ID:
				modifyDict[fileName] = int(round(os.path.getmtime(fileName)))

		except Exception, e:
			# raise
			print fileName, utf2local('文件无法被生成！(检查是否多了无效列)')
			print '[', '-'*50, 'begin exception'
			# print lines
			print e
			traceback.print_exc()
			print '-'*50, ']', 'end exception'

	modifyListFile = open(MODIFY_FILENAME,"w")
	seq = [k + "," + str(v) +"\n" for (k, v) in modifyDict.items()]
	modifyListFile.writelines(seq)
	modifyListFile.close()
	if hasNewFile:
		writeSrc(luaSrc)
	print LUA_FILE_NAME, 'finished'

if __name__ == '__main__':
	from pyservcfg import *
	# from luacfg import *

	global SRC_PATH, LANGUAGE
	SRC_PATH = "../../../config_dev"
	LANGUAGE = 'cn'

	main()

	# from luacfg import *
	# TABLE_SLIM_REDUNDANCY = False

	# s = "<'0.4+((self:Ghp()/self:GhpMax())<0.5 and 0.1 or 0)'; '0.3+((self:Ghp()/self:GhpMax())<0.5 and 0.2 or 0)'>"
	# # s = '<"0.4+((self:Ghp()/self:GhpMax())<0.5 and 0.1 or 0)"; "0.3+((self:Ghp()/self:GhpMax())<0.5 and 0.2 or 0)">'
	# # print makeArray(s)


	# test = [
	# 	# 字符串 self._scene:getClassifyCount(self.force,37) >0 and 1 or 0;self._scene:getClassifyCount(self.force,37) >0 and 1 or 0
	# 	'''"self._scene:getClassifyCount(self.force,37) >0 and 1 or 0;self._scene:getClassifyCount(self.force,37) >0 and 1 or 0"''',

	# 	# 不合法数组 <self._scene:getClassifyCount(self.force,37) >0 and 1 or 0;self._scene:getClassifyCount(self.force,37) >0 and 1 or 0>
	# 	'''"<self._scene:getClassifyCount(self.force,37) >0 and 1 or 0;self._scene:getClassifyCount(self.force,37) >0 and 1 or 0>"''',

	# 	# 字符串数组 <'self._scene:getClassifyCount(self.force,37) >0 and 1 or 0';'self._scene:getClassifyCount(self.force,37) >0 and 1 or 0'>
	# 	'''"<'self._scene:getClassifyCount(self.force,37) >0 and 1 or 0';'self._scene:getClassifyCount(self.force,37) >0 and 1 or 0'>"''',

	# 	# 字符串数组 <"self._scene:getClassifyCount(self.force,37) >0 and 1 or 0";"self._scene:getClassifyCount(self.force,37) >0 and 1 or 0">
	# 	'''"<""self._scene:getClassifyCount(self.force,37) >0 and 1 or 0"";""self._scene:getClassifyCount(self.force,37) >0 and 1 or 0"">"''',

	# 	# 字符串 "<self._scene:getClassifyCount(self.force,37) >0 and 1 or 0;self._scene:getClassifyCount(self.force,37) >0 and 1 or 0>"
	# 	'''"""<self._scene:getClassifyCount(self.force,37) >0 and 1 or 0;self._scene:getClassifyCount(self.force,37) >0 and 1 or 0>"""''',

	# 	# 字符串 "<1;2;3>"
	# 	'''"""<1;2;3>"""''',

	# 	# 数组 <self._scene:getClassifyCount(self.force,37) >0 and 1 or 0;";";';';self._scene:getClassifyCount(self.force,37) >0 and 1 or 0>
	# 	'''"<self._scene:getClassifyCount(self.force,37) >0 and 1 or 0;"";"";';';self._scene:getClassifyCount(self.force,37) >0 and 1 or 0>"''',

	# 	# 数组 <1;2;3;"<a;b;'x';c>";4>
	# 	'''"<1;2;3;""<a;b;'x';c>"";4>"''',
	# ]
	# for s in test:
	# 	print '-'*20
	# 	print 'raw: ', s
	# 	print 'lua: ', showTypeString(whatType(s)), autoMake(s)


