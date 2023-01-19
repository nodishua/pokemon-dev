#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework.object import ObjectDBase, db_property, ObjectNoGCDBase
from game.object import MailDefs

#
# ObjectMailGlobal
#

class ObjectMailGlobal(ObjectNoGCDBase):
	'''
	MailGlobal是公共对象，不进行GC
	'''
	DBModel = 'MailGlobal'

	Singleton = None

	def __init__(self, dbc):
		ObjectDBase.__init__(self, None, dbc)

		if ObjectMailGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectMailGlobal.Singleton = self

	# 全局邮件缩略数据 [{db_id:Mail.id, subject:Mail.subject, time:Mail.time, type=Mail.type, sender:Mail.sender}, ...]
	def mails():
		dbkey = 'mails'
		def fset(self, value):
			self.db[dbkey] = value
		return locals()
	mails = db_property(**mails())

	@classmethod
	def addGlobalMail(cls, mailID, subject, time, mailType, sender='', hasattach=True):
		cls.Singleton.mails.append({
			'db_id': mailID,
			'subject': subject,
			'time': time,
			'type': mailType,
			'mtype': MailDefs.TypeGlobal,
			'sender': sender,
			'hasattach': hasattach,
		})

	@classmethod
	def addServerMail(cls, mailID, subject, time, mailType, sender='', hasattach=True):
		cls.Singleton.mails.append({
			'db_id': mailID,
			'subject': subject,
			'time': time,
			'type': mailType,
			'mtype': MailDefs.TypeServer,
			'sender': sender,
			'hasattach': hasattach,
		})

	@classmethod
	def addVipMail(cls, beginVip, endVip, mailID, subject, time, mailType, sender='', hasattach=True):
		cls.Singleton.mails.append({
			'db_id': mailID,
			'beginVip': beginVip,
			'endVip': endVip,
			'subject': subject,
			'time': time,
			'type': mailType,
			'mtype': MailDefs.TypeVip,
			'sender': sender,
			'hasattach': hasattach,
		})

	@classmethod
	def countMails(cls):
		return len(cls.Singleton.mails)

	@classmethod
	def getMails(cls, offest):
		return cls.Singleton.mails[offest:]

