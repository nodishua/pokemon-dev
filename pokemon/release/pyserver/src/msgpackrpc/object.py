#!/usr/bin/python
# -*- coding: utf-8 -*-

ModName = '__modname__'
ClsName = '__clsname__'
CustomData = '__data__'
StandardData = '__vars__'
ObjectFlag = '__object__'



def _obj_pack_to(obj):
	t = type(obj)
	if t.__name__ in ('list', 'tuple'):
		conv = None
		for i, v in enumerate(obj):
			vv, flag = _obj_pack_to(v)
			if flag:
				conv = conv if conv else obj[:i-1]
				conv.append(vv)
		return conv if conv else obj, conv != None

	elif t.__name__ == 'dict':
		conv = None
		keys = obj.keys()
		for i, k in enumerate(keys):
			vv, flag = _obj_pack_to(obj[k])
			if flag:
				conv = conv if conv else {keys[j]: obj[keys[j]] for j in xrange(i)}
				conv[k] = vv
		return conv if conv else obj, conv != None

	elif t.__module__ == '__builtin__':
		return obj, False

	ret = {
		ModName: t.__module__,
		ClsName: t.__name__,
	}
	flag = True

	# namedtuple
	if hasattr(obj, '_fields'):
		ret[ModName] = 'namedtuple'
		ret[CustomData] = NamedtupleAdapter.pack_to(obj)

	elif isinstance(obj, PackObject):
		ret[CustomData] = obj.pack_to()

	elif t.__name__ in Adapters:
		ret[CustomData] = Adapters[t.__name__].pack_to(obj)

	elif hasattr(obj, '__dict__') or hasattr(obj, '__slots__'):
		ret[StandardData] = vars(obj)

	else:
		ret = None

	return ret, flag

def obj_pack_to(obj):
	ret, flag = _obj_pack_to(obj)
	if flag:
		return {ObjectFlag: ret}
	return obj

# modify in place
def _obj_unpack_from(d):
	if not isinstance(d, dict) or ModName not in d:
		if isinstance(d, (tuple, list)):
			if isinstance(d, tuple):
				d = list(d)
			for i, v in enumerate(d):
				vv = _obj_unpack_from(v)
				if vv:
					d[i] = vv

		elif isinstance(d, dict):
			for k, v in d.iteritems():
				vv = _obj_unpack_from(v)
				if vv:
					d[k] = vv

		return d

	# namedtuple
	if d[ModName] == 'namedtuple':
		return NamedtupleAdapter.unpack_from(d[CustomData])

	elif d[ClsName] in Adapters:
		return Adapters[d[ClsName]].unpack_from(d[CustomData])

	mod = __import__(d[ModName])
	cls = getattr(mod, d[ClsName])

	if CustomData in d:
		return cls.unpack_from(d[CustomData])

	else:
		return None


def obj_unpack_from(d):
	if isinstance(d, dict) and ObjectFlag in d:
		return _obj_unpack_from(d[ObjectFlag])
	return d

'''
python基础类型不转换
python库类型adapter自动转换
自定义类型通过继承PackObject的公共类来自动转换
'''

class PackObject(object):
	def __init__(self, d):
		self.data = d

	def pack_to(self):
		return self.data

	@classmethod
	def unpack_from(cls, data):
		return PackObject(data)


from collections import namedtuple
class NamedtupleAdapter(object):
	ClsMap = {}

	@classmethod
	def pack_to(cls, obj):
		return {
			ClsName: type(obj).__name__,
			StandardData: vars(obj).items(),
		}

	@classmethod
	def unpack_from(cls, data):
		items = data[StandardData]
		# 同名namedtuple需要相同结构
		if data[ClsName] in cls.ClsMap:
			tcls = cls.ClsMap[data[ClsName]]
		else:
			tcls = namedtuple(data[ClsName], [t[0] for t in items])
			cls.ClsMap[data[ClsName]] = tcls
		return tcls(*[t[1] for t in items])


import time
from datetime import datetime, date
class DatetimeAdapter(object):
	@classmethod
	def pack_to(cls, obj):
		return {
			ClsName: type(obj).__name__,
			StandardData: time.mktime(obj.timetuple()),
		}

	@classmethod
	def unpack_from(cls, data):
		if data[ClsName] == 'datetime':
			return datetime.fromtimestamp(data[StandardData])
		elif data[ClsName] == 'date':
			return date.fromtimestamp(data[StandardData])


Adapters = {
	'datetime': DatetimeAdapter,
	'date': DatetimeAdapter,
}





if __name__ == '__main__':
	import unittest
	class TestMethods(unittest.TestCase):
		def test_dict(self):
			d = {1:'11', 2:'22', 3:[1,2,3], 4:{'aa':1, 'bb':'22'}, (1,2):{'a':1,'b':{}}}
			data = obj_pack_to(d)
			obj = obj_unpack_from(data)
			self.assertEqual(d, obj)

		def test_nametuple(self):
			from collections import namedtuple
			N = namedtuple('N', ['a', 'b'])
			n = N(11, 22)
			data = obj_pack_to(n)
			obj = obj_unpack_from(data)
			self.assertEqual(n, obj)

		def test_nametuple2(self):
			from collections import namedtuple

			N = namedtuple('N', ['a', 'b'])
			n = N(11, 22)
			data = obj_pack_to(n)
			obj = obj_unpack_from(data)
			self.assertEqual(n, obj)

			# 不允许同名namedtuple
			try:
				N = namedtuple('N', ['a', 'b', 'c', 'd'])
				n = N(11, 22, [1,2], {4:{'aa':1, 'bb':'22'}})
				data = obj_pack_to(n)
				obj = obj_unpack_from(data)
				self.assertTrue(False)
			except:
				self.assertTrue(True)

		def test_datetime(self):
			from datetime import datetime
			dt = datetime(2001,2,3)
			data = obj_pack_to(dt)
			obj = obj_unpack_from(data)
			self.assertEqual(dt, obj)

		def test_date(self):
			from datetime import date
			dt = date(2001,2,3)
			data = obj_pack_to(dt)
			obj = obj_unpack_from(data)
			self.assertEqual(dt, obj)

	unittest.main()


# kernprof -l -v object.py
# @profile
# def test_nametuple():
# 	from collections import namedtuple
# 	N = namedtuple('N', ['a', 'b'])
# 	n = N(11, 22)
# 	for i in xrange(100):
# 		data = obj_pack_to(n)
# 		obj = obj_unpack_from(data)
# test_nametuple()


# py.test object.py
# def test_nametuple_pack(benchmark):
# 	from collections import namedtuple
# 	N = namedtuple('N', ['a', 'b'])
# 	n = N(11, 22)
# 	@benchmark
# 	def test():
# 		data = obj_pack_to(n)


# def test_nametuple_unpack(benchmark):
# 	from collections import namedtuple
# 	N = namedtuple('N', ['a', 'b'])
# 	n = N(11, 22)
# 	data = obj_pack_to(n)
# 	@benchmark
# 	def test():
# 		obj = obj_unpack_from(data)