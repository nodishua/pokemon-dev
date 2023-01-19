#!/usr/bin/python
# -*- coding: utf-8 -*-


class ObjectDictAttrs(dict):

	def __init__(self, dic=None):
		dict.__init__(self)
		if dic:
			assert isinstance(dic, dict), "must be dict object"
			for k, v in dic.items():
				setattr(self, k, v)

	def __setattr__(self, key, value):
		self.__setitem__(key, value)

	def __setitem__(self, key, value):
		if isinstance(key, (str, unicode)):
			super(ObjectDictAttrs, self).__setattr__(key, value)
		super(ObjectDictAttrs, self).__setitem__(key, value)