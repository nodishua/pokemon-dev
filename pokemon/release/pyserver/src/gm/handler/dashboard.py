# -*- coding: utf-8 -*-

from __future__ import absolute_import

from tornado.gen import coroutine
from tornado.web import HTTPError

from .base import BaseHandler, AuthedHandler
from ..object.session import Session, SESSION_KEY
from ..object.scheme import User
from gm.util import calc_md5, datetime2str

import time
import datetime


class LoginHandler(BaseHandler):
	url = "/login"

	@coroutine
	def get(self):
		self.render_page("login.html", error="")

	@coroutine
	def post(self):
		username = self.get_argument("username")
		password = self.get_argument("password")

		pass_md5 = calc_md5(password)

		if Session.existSession(username):
			session = Session.getSession(username)
			if session.pass_md5 == pass_md5:
				sessionID = session.resetIdent()
				self.set_secure_cookie(SESSION_KEY, sessionID)
				self.redirect("/")
			else:
				self.render("login.html", error=self.translate(u"Username or password is incorrect"), userLocale=self.language)
		else:
			account = User.find_one(self.mongo_client, {"name": username})
			if not account or account["pass_md5"] != pass_md5:
				self.render("login.html", error=self.translate(u"Username or password is incorrect"), userLocale=self.language)
			else:
				session = Session(account)
				# Set a default language for the account，framework.__language__
				# session.setLanguage(self.language)
				self.set_secure_cookie(SESSION_KEY, session.sessionID)
				self.redirect("/")


class LogoutHandler(AuthedHandler):
	url = "/logout"

	@coroutine
	def get(self):
		self.current_user.logout()
		self.clear_cookie(SESSION_KEY)
		self.redirect("/login")


class HomePageHandler(AuthedHandler):
	url = "/"
	QueryLimit = [0, time.time()]
	QueryResult = ['x', 0, 0, 0] # activate, sign, recharge, amount

	@coroutine
	def get(self):
		if self.QueryLimit[0] > 0 and time.time() - self.QueryLimit[1] < 5*60:
			self.render_page("dashboard.html", overview=QueryResult)
			return
		self.QueryResult[1] = self.mongo_client.Account.count()
		self.QueryResult[2] = self.mongo_client.Account.count({'first_pay_time': {'$gt': 0.0}})
		orderAmount = self.mongo_client.Cursor.find_one({'cur_name': 'cur_order_amount'})
		self.QueryResult[3] = orderAmount['cur_value'] if orderAmount else 0.0
		self.render_page("dashboard.html", overview=self.QueryResult)


class languageSetHandler(AuthedHandler):
	url = "/lanauge_set"

	@coroutine
	def get(self):
		language = self.get_argument("lang")
		self.current_user.setLanguage(language)
		referer = self.request.headers.get("Referer", None)
		if referer:
			self.redirect(referer)
		else:
			self.redirect("/")


class AccountCreationHandler(AuthedHandler):
	url = "/create_account"

	@coroutine
	def get(self):
		name = self.get_argument("name")
		if not Session.existSession(name):
			account = User.find_one(self.mongo_client, {"name": name})
			if not account:
				self.write_json({"ret": True,})
				return
		self.write_json({"ret": False,})

	@coroutine
	def post(self):
		if self.current_user.permission < 999:
			raise HTTPError(504, "NOT Enough Permisson")

		requestData = self.get_json_data()
		pass_md5 = calc_md5(requestData['pwd'])
		nowS = datetime2str(datetime.datetime.now())

		data = {
			"name": requestData["name"],
			"pass_md5": pass_md5,
			"permission_level": int(requestData["level"]),
			"create_time": nowS,
			"last_time": nowS
		}

		User.insert_one(self.mongo_client, data)

		self.write_json({"ret": True, "data": "success"})

class Test(BaseHandler):
	url = '/test'

	def get(self):
		self.render_page('recharge.html')