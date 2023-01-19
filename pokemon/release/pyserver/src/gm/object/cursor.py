#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.
'''
from __future__ import absolute_import

from gm.object.db import DBRecord


class DBCursor(DBRecord):
	Collection = 'Cursor'
	Indexes = [{'index': 'cur_name', 'unique': True}]

	@staticmethod
	def defaultDocument():
		return {
			'cur_name': 'none',
			'cur_value': 'none'
		}
