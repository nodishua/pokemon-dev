#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

The Game Server
'''

from tornado.web import HTTPError
from nsqrpc.error import CallError

'''
Error
'''
class BaseHTTPError(HTTPError):
	def __init__(self, code, err=None, **kwargs):
		if isinstance(err, CallError):
			HTTPError.__init__(self, code, str(err.msg))
			kwargs.update(err.kwargs)
		else:
			HTTPError.__init__(self, code, str(err))
		self.kwargs = kwargs

class ServerError(BaseHTTPError):
	def __init__(self, err=None, **kwargs):
		BaseHTTPError.__init__(self, 500, err, **kwargs)

class ClientError(BaseHTTPError):
	def __init__(self, err=None, **kwargs):
		BaseHTTPError.__init__(self, 400, err, **kwargs)

class AuthError(BaseHTTPError):
	def __init__(self):
		BaseHTTPError.__init__(self, 401, '20001') # ErrDefs.sessionError

class CheatError(BaseHTTPError):
	def __init__(self):
		BaseHTTPError.__init__(self, 401, '20002') # ErrDefs.sessionError

