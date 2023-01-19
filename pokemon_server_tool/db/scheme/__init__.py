#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''


import account
import game
import pvp
import order
import cross
from db.redisorm import Model

modules = [
	account,
	game,
	pvp,
	order,
	cross,
]
models = {}

def _makeModelsMap():
	for m in modules:
		for x in dir(m):
			cls = getattr(m, x)
			try:
				if issubclass(cls, Model):
					models[cls.__name__] = cls
			except Exception:
				pass
	# print models

_makeModelsMap()