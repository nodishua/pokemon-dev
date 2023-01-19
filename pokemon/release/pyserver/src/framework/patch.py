#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import
import sys

# maps module name -> attribute name -> original item
# e.g. "time" -> "sleep" -> built-in function sleep
saved = {}

def _get_original(name, items):
	d = saved.get(name, {})
	values = []
	module = None
	for item in items:
		if item in d:
			values.append(d[item])
		else:
			if module is None:
				module = __import__(name)
			values.append(getattr(module, item))
	return values


def get_original(name, item):
	if isinstance(item, basestring):
		return _get_original(name, [item])[0]
	else:
		return _get_original(name, item)


def patch_item(module, attr, newitem):
	olditem = getattr(module, attr, None)
	if olditem is not None:
		saved.setdefault(module.__name__, {}).setdefault(attr, olditem)
	setattr(module, attr, newitem)


def remove_item(module, attr):
	olditem = getattr(module, attr, None)
	if olditem is None:
		return
	saved.setdefault(module.__name__, {}).setdefault(attr, olditem)
	delattr(module, attr)


def patch_module(mymodule, stdmodule, items):
	__import__(mymodule) # returns the toplevel module here
	__import__(stdmodule)
	my_module = sys.modules[mymodule]
	module = sys.modules[stdmodule]
	for my_attr, attr in items:
		patch_item(module, attr, getattr(my_module, my_attr))


def patch_tornado():
	patch_module('framework.ymconnection', 'tornado.http1connection', [
		('YMConnection', 'HTTP1Connection'),
		('YMServerConnection', 'HTTP1ServerConnection'),
	])


# patch_tornado()

