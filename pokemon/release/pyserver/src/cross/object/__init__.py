#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework.object import ObjectDicAttrs

from tornado.gen import moment

class RemoteObject(ObjectDicAttrs):
	def __init__(self, fufunc, dic):
		self.__dict__['_dic'] = dic
		self.__dict__['_fufunc'] = fufunc
		self.__dict__['_changes'] = set()

	def __setattr__(self, name, value):
		if name in self._dic:
			self._dic[name] = value
			self._changes.add(name)
		else:
			self.__dict__[name] = val

	def __delattr__(self, name):
		if name in self._dic:
			self._dir.pop(name)
			self._changes.add(name)
		else:
			self.__dict__.pop(name, None)

	def changed(self, name):
		self._changes.add(name)

	def save_async(self):
		if self.changes and self.fufunc:
			d = {k: self._dic.get(k, None) for k in self.changes}
			self.changes.clear()
			return fufunc(d)
		return moment


def initAllClass():
	# ObjectPWRange.classInit()
	pass

initAllClass()
