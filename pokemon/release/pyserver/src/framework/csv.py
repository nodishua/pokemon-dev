#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

from framework import Languages
from framework.helper import ClassProperty

import os
import sys
import time
import copy
import functools

class CsvIterator(object):
	def __init__(self, it):
		self._it = it

	def __iter__(self):
		return self

	def next(self):
		n = self._it.next()
		if n == '__default':
			n = self._it.next()
		return n

class Csv(object):
	dic = None
	Version = 0
	DictCache = {}

	@classmethod
	def load(cls):
		if Csv.dic:
			return

		import framework
		import framework.csv2py.csv2src
		import framework.csv2py.pyservcfg
		from framework.log import logger

		csv2src = framework.csv2py.csv2src
		cfg = framework.csv2py.pyservcfg

		try:
			os.remove(cfg.LUA_FILE_NAME + 'c')
		except Exception, e:
			pass
		try:
			os.remove(cfg.LUA_FILE_NAME + 'o')
		except Exception, e:
			pass

		# Development period Judgment module automatically generates CSV when py
		# The module is pyc after packing, and CSV is not automatically generated
		if hasattr(framework, '__dev__'):
			if hasattr(framework, '__dev_config__'):
				cfg.SRC_PATH = framework.__dev_config__
			cfg.LANGUAGE = framework.__language__
			cfg.LUA_FILE_NAME = '%s_config_csv.py' % framework.__language__

			logger.info('Python Csv generated %s %s %s', cfg.__doc__, cfg.LUA_FILE_NAME, cfg.SRC_PATH)

			try:
				os.remove(cfg.LUA_FILE_NAME)
			except Exception, e:
				pass

			# import gc
			# gc.collect()
			# print 111111111111,process_info()

			# csv2src.__dict__.update(cfg.__dict__)
			# csv2src.main()

			import subprocess
			cmd = "chmod +x tool/csv2src && tool/csv2src -language=%s -input=%s -output=%s -outputFile=%s" % (cfg.LANGUAGE, cfg.SRC_PATH, "./", cfg.LUA_FILE_NAME)
			p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
			out, _ = p.communicate()
			logger.info("%s", out)
			if 'panic' in out:
				raise Exception("csv2src error")

			cfg = None
			csv2src = None

		# gc.collect()
		# print 222222222222,process_info()

		name = '%s_config_csv' % framework.__language__
		_csv = __import__(name)
		_csv = reload(_csv)
		Csv.dic = _csv.csv

		# gc.collect()
		# print 33333333333,process_info()

	@classmethod
	def reload(cls):
		global csv
		from framework.log import logger

		oldID = id(Csv.dic)
		logger.info('CSV reload before, %d %d %d' % (cls.Version, id(csv.dic), id(Csv.dic)))
		Csv.dic = None
		Csv.load()
		csv.reset() # global csv地址不变，更改成员
		ErrDefs.classInit()
		L10nDefs.classInit()
		ConstDefs.classInit()
		Csv.refreshCache()
		logger.info('CSV reload after, %d %d %d' % (cls.Version, id(csv.dic), id(Csv.dic)))
		if oldID == id(Csv.dic):
			logger.warning('CSV reload may be failed!')

	@classmethod
	def refreshCache(cls):
		global csv

		cls.Version = int(time.time() - 1400000000)
		cls.DictCache = {'yunying': csv.yunying.to_dict()}

	@classmethod
	def isCSV(cls, val):
		return isinstance(val, str) and (val[:4] == 'csv[' or val[:4] == 'csv.')

	@classmethod
	def getCSV(cls, val):
		if not cls.isCSV(val):
			raise ValueError('It is not CSV value.')
		return eval(val)

	@classmethod
	def _r_to_dict(cls, dic, defDic):
		if hasattr(dic, '_fields'):
			d = dict(zip(dic._fields, dic))
			if defDic:
				for k in d:
					if d[k] is None:
						d[k] = getattr(defDic, k)
			# 缩减其它语言配置，减少同步给client的数据量
			import framework
			for k in dic._fields:
				# sg只是数果cn的专服
				if framework.__language__ not in ('cn', 'sg'):
					kk = '%s_%s' % (k, framework.__language__)
					if kk in d:
						d[k] = d[kk]
				for kk in ['%s_%s' % (k, x) for x in Languages]:
					d.pop(kk, None)
			return d

		d = copy.copy(dic)
		if not isinstance(d, dict):
			return d

		ddef = d.pop('__default', None)
		for k in d:
			d[k] = cls._r_to_dict(d[k], ddef)
		return d

	@property
	def id(self):
		return self.myID

	def __init__(self, myID=None, dic=None, defDic=None):
		if dic is not None:
			self.rawSetAttr('dic', dic)
			self.rawSetAttr('defDic', defDic)
			self.rawSetAttr('isDict', isinstance(dic, dict))
		else:
			Csv.load()
			self.rawSetAttr('dic', Csv.dic)
			self.rawSetAttr('defDic', None)
			self.rawSetAttr('isDict', True)

		if myID is not None:
			try:
				old = myID
				myID = int(myID)
				# 这里是为了检测
				if myID <= 0:
					print "who set error ID, %s %d %s" % (old, myID, type(dic))
					# myID = None
			except ValueError:
				myID = None
		self.rawSetAttr('myID', myID)
		self.rawSetAttr('odic', {})

		if not self.isDict:
			import framework
			if framework.__language__ not in ('cn', 'sg'):
				suffix = '_%s' % framework.__language__
				l10n = {}
				for field in self.dic._fields:
					if field.endswith(suffix):
						val = getattr(self.dic, field)
						if val is None and self.defDic:
							val = getattr(self.defDic, field)
						l10n[field[:-3]] = val
				if l10n:
					self.rawSetAttr('dic', self.dic._replace(**l10n))

	def to_dict(self):
		return self._r_to_dict(self.dic, self.defDic)

	def reset(self):
		self.rawSetAttr('dic', Csv.dic)
		self.rawSetAttr('defDic', None)
		self.rawSetAttr('myID', None)
		self.rawSetAttr('odic', {})
		self.rawSetAttr('isDict', True)

	def iterkeys(self):
		if self.isDict:
			return CsvIterator(self.dic.iterkeys())
		return iter(self.dic._fields)

	def keys(self):
		if self.isDict:
			keyL = self.dic.keys()
			if '__default' in keyL:
				keyL.remove('__default')
			return keyL
		return self.dic._fields

	def __len__(self):
		if self.isDict:
			return len(self.dic) - (1 if '__default' in self.dic else 0)
		return len(self.dic._fields)

	def __setitem__(self, key, message):
		raise AttributeError('Csv can not be set item!')

	def __getattr__(self, name):
		val = None
		if self.isDict:
			if name in self.odic:
				val = self.odic[name]
			elif name in self.dic:
				val = self.dic[name]
				val = Csv(name, val, self.dic.get('__default', None))
				self.odic[name] = val
		else:
			val = getattr(self.dic, name)
			if val is None and self.defDic:
				val = getattr(self.defDic, name)
		return val

	def __setattr__(self, name, value):
		raise AttributeError('Csv can not be set attr!')

	def __contains__(self, item):
		if self.isDict:
			return item in self.dic
		return item in self.dic._fields

	__getitem__ = __getattr__
	__iter__ = iterkeys

	def rawSetAttr(self, name, value):
		self.__dict__[name] = value


class ErrDefs(object):
	@classmethod
	def classInit(cls):
		for id in csv.language:
			if id >= 5000:
				continue
			cfg = csv.language[id]
			if cfg.key:
				setattr(cls, cfg.key, cfg.key)

class L10nDefs(object):
	@classmethod
	def classInit(cls):
		import framework
		field = 'text'

		for id in csv.language:
			cfg = csv.language[id]
			if cfg.key:
				def fget(cfg, cls):
					raw = getattr(cfg, field)
					if framework.__language__ != 'cn':
						field2 = '%s_%s' % (field, framework.__language__)
						return getattr(cfg, field2, raw)
					return raw
				setattr(cls, cfg.key, ClassProperty(functools.partial(fget, cfg)))

class ConstDefs(object):
	@classmethod
	def classInit(cls):
		for id in csv.common_config:
			if id >= 5000:
				continue
			cfg = csv.common_config[id]
			if cfg:
				setattr(cls, cfg.name, cfg.value)

class MergeServ(object):
	DestServMerge = {} # {gamemerge.1: [game.1, ...]}
	DestServAreas = {} # {gamemerge.1: [1, 2, 3]}
	SrcServMerge = {} # {game.1 : gamemerge.1}
	ServCfg = {} # {gamemerge.1: cfg}

	@classmethod
	def classInit(cls):
		cls.DestServMerge = {}
		cls.DestServAreas = {}
		cls.SrcServMerge = {}
		cls.ServCfg = {}

		mergemap = {}
		mergesDestL = []
		for idx in sorted(csv.server.merge.keys()):
			cfg = csv.server.merge[idx]
			if cfg.realityMerge != 1:
				continue
			mergemap[cfg.destServer] = cfg.servers
			cls.ServCfg[cfg.destServer] = cfg
			mergesDestL.append(cfg.destServer)

		def destServ2SrcServ(dest):
			srcServ = mergemap[dest]
			servs = []
			for serv in srcServ:
				if serv in mergemap:
					if serv != dest:
						servs.extend(destServ2SrcServ(serv))
					else:
						servs.append(serv)
				else:
					servs.append(serv)
			return servs

		for dest in mergesDestL:
			srcs = destServ2SrcServ(dest)
			cls.DestServMerge[dest] = srcs
			cls.DestServAreas[dest] = [int(key.split('.')[-1]) for key in srcs]
			for src in srcs:
				cls.SrcServMerge[src] = dest

	# 原始服名 -> 合服名,没有则返回自身
	@classmethod
	def getMergeServKey(cls, srcKey):
		return cls.SrcServMerge.get(srcKey, srcKey)

	# 是否已经被合服
	@classmethod
	def isMerged(cls, srcKey):
		return srcKey in cls.SrcServMerge

	# 合服名 -> 原始服名列表
	@classmethod
	def getSrcServKeys(cls, mergeKey):
		return cls.DestServMerge.get(mergeKey, [mergeKey])

	# 合服名 -> 原始服名序号列表
	@classmethod
	def getSrcServAreas(cls, mergeKey):
		return cls.DestServAreas.get(mergeKey, [int(mergeKey.split('.')[-1])])

	# 合服名 -> cfg
	@classmethod
	def getServCfg(cls, servKey):
		return cls.ServCfg.get(servKey, None)

	# 是否是 该合服名 下的 原始服
	@classmethod
	def inSubServer(cls, destKey, srcKey):
		return srcKey in cls.DestServMerge.get(destKey, [])

	# 是否是合服名
	@classmethod
	def isServMerged(cls, servKey):
		if servKey not in cls.DestServMerge:
			return False
		srcKeys = cls.DestServMerge.get(servKey)
		if len(srcKeys) > 1 or srcKeys[0] != servKey:
			return True
		return False

	@classmethod
	def slimServNames(cls, servKeys):
		keys = set()
		for key in servKeys:
			keys.add(cls.getMergeServKey(key))
		retKeys = []
		for key in keys:
			retKeys.append(cls.getSrcServKeys(key)[0])
		return retKeys

csv = Csv()
csv.refreshCache()
ErrDefs.classInit()
L10nDefs.classInit()
ConstDefs.classInit()
MergeServ.classInit()
# print L10nDefs.WorldServerMaintain