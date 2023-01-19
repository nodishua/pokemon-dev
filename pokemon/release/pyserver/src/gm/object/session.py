#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

from framework.log import logger

import uuid
import time


SESSION_KEY = "TJ_GM_SESSIONID"

LOCALE_NAMES = {
	'cn': 'zh_CN',
	'en': 'en_US',
	'vn': 'vi_VN',
}

class Session(object):
	Sessions = {} # Record the session of the login user {sessionid: session}
	IDMap = {} # Map of username and session ID{name: SessionID}

	@classmethod
	def addSession(cls, session):
		cls.IDMap[session.name] = session.sessionID
		cls.Sessions[session.sessionID] = session

	@classmethod
	def removeSession(cls, session):
		cls.Sessions.pop(session.sessionID, None)
		cls.IDMap.pop(session.name, None)

	@classmethod
	def existSession(cls, ns):
		return (ns in Session.Sessions) or (ns in Session.IDMap)

	@classmethod
	def getSessionByID(cls, sessionID):
		return cls.Sessions.get(sessionID, None)

	@classmethod
	def getSessionID(cls, name):
		return cls.IDMap.get(name, None)

	@classmethod
	def getSession(cls, name):
		sessionID = cls.getSessionID(name)
		if sessionID:
			return cls.getSessionByID(sessionID)
		return None

	def __init__(self, account):
		self._account = account
		self.online = True
		self.lang = None
		self._ident = self.createIdent()

		Session.addSession(self)

	@property
	def name(self):
		return self._account.name

	@property
	def pass_md5(self):
		return self._account.pass_md5

	@property
	def permission(self):
		return self._account.permission_level

	@property
	def operated_history(self):
		return self._account.operated_history

	@property
	def sessionID(self):
		return self._ident

	def setLanguage(self, lang):
		lang = lang.replace("-", "_")
		parts = lang.split("_")

		if len(parts) == 1:
			code = LOCALE_NAMES.get(parts[0].lower(), None)
		elif len(parts) == 2:
			code = parts[0].lower() + "_" + parts[1][:2].upper()
			if code not in LOCALE_NAMES.values():
				code = None
		else:
			code = None

		if not code:
			logger.warning("`%s` Not Support This Lanauge `%s`"% (self.name, lang))
		self.lang = code

	@property
	def language(self):
		return self.lang

	def createIdent(self):
		ident = str(self.name) + str(time.time())
		sessionID = uuid.uuid5(uuid.NAMESPACE_DNS, ident)
		return str(sessionID)

	def resetIdent(self):
		Session.removeSession(self)
		self._ident = self.createIdent()
		self.online = True
		Session.addSession(self)
		return self.sessionID

	def logout(self):
		session = Session.getSession(self.name)
		if session:
			session.online = False

	def __str__(self):
		return "<Session Object name=`%s` sessionID=`%s` permission=`%d`>"% (self.name,
			self.sessionID, self.permission)


class SessionError(Exception):
	pass


if __name__ == '__main__':
	u1 = Session("MLC", "123ZXC", 999)
	u2 = Session('ASD', "QWE", 111)
	print u2
	print Session.IDMap
	print Session.Sessions
	print Session.getSession(u1.name)
	print u1.logout()
	print u1.online
	time.sleep(1)
	print u2.resetIdent()
	print u2
	print Session.Sessions
