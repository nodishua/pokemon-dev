#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

from .handler import handlers

import tornado.httpserver
import tornado.web
import tornado.locale
import os
import base64
import uuid


I18N_PATH = os.path.join(os.path.dirname(__file__), 'locales')

settings = dict(
	template_path = os.path.join(os.path.dirname(__file__), "templates"),
	static_path = os.path.join(os.path.dirname(__file__), "statics"),
	static_url_prefix = "/statics/",
	cookie_secret = base64.b64encode(uuid.uuid4().bytes),
	debug = False,
	autoreload = False,
	gzip = True,
	static_hash_cache = False,
)

class HTTPServer(tornado.httpserver.HTTPServer):

	def __init__(self, **kwargs):
		tornado.locale.load_translations(I18N_PATH)
		debug = kwargs.pop('debug', False)
		if debug:
			settings['debug'] = True
		self.application = tornado.web.Application(handlers, **settings)
		tornado.httpserver.HTTPServer.__init__(self, self.application, **kwargs)
