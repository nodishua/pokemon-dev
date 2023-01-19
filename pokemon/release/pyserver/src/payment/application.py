#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from payment.sdk.uc import SDKUC
from payment.sdk.qh360 import SDK360
from payment.sdk.mi import SDKMi, SDKMi_blbxz
from payment.sdk.baidu import SDKBaidu
from payment.sdk.hj import SDKHuawei, SDKOppo, SDKVivo, SDKCoolPad, SDKGionee, SDKLenovo
from payment.sdk.lj import SDKLJ
from payment.sdk.sina import SDKSina
from payment.sdk.ouwan import SDKOuwan, SDKOuwan_blbxz
from payment.sdk.apple import SDKApple
from payment.sdk.qq import SDKQQ, SDKWX
from payment.sdk.yijie import SDKYijie
from payment.sdk.mz import SDKMeizu
from payment.sdk.tt import SDKTT
from payment.sdk.lb import SDKLB
from payment.sdk.pyw import SDKPyw
from payment.sdk.ls import SDKLs
from payment.sdk.yw import SDKYw
from payment.sdk.tc import SDKTc
from payment.sdk.quick import SDKQuick
from payment.sdk.zhuodong import SDKZhuodong
from payment.sdk.lunplay import SDKLunplay, SDKLunplayVN, SDKLunplayKR, SDKLunplayEN, SDKLunplayGift
from payment.sdk.kaisa import SDKKaisa
from payment.sdk.xiaoy import SDKXiaoY
from payment.sdk.mofang import *
from payment.sdk.test import SDKTest
from payment.sdk.tjgame import SDKTJGame

from tornado import web
from tornado.gen import coroutine, Return


class BasePayment(web.RequestHandler):
	SDKClass = None

	@coroutine
	def get(self):
		ret = yield self.SDKClass.payCallback(self)
		self.write(ret)

	@coroutine
	def post(self):
		ret = yield self.SDKClass.payCallback(self, False)
		self.write(ret)

class TestCreate(web.RequestHandler):
	@coroutine
	def post(self):
		ret = yield SDKTest.createCallback(self, False)
		self.write(ret)

class TestPayment(BasePayment):
	SDKClass = SDKTest

class TJGameCreate(web.RequestHandler):
	@coroutine
	def post(self):
		ret = yield SDKTJGame.createCallback(self, False)
		self.write(ret)

class TJGamePayment(BasePayment):
	SDKClass = SDKTJGame

class UCCreate(web.RequestHandler):
	@coroutine
	def post(self):
		ret = yield SDKUC.createCallback(self, False)
		self.write(ret)


class UCPayment(BasePayment):
	SDKClass = SDKUC


class BaiduPayment(BasePayment):
	SDKClass = SDKBaidu


class QH360Payment(BasePayment):
	SDKClass = SDK360


class MiPayment(BasePayment):
	SDKClass = SDKMi


class Mi_blbxzPayment(BasePayment):
	SDKClass = SDKMi_blbxz


class HuaweiPayment(BasePayment):
	SDKClass = SDKHuawei


class OppoPayment(BasePayment):
	SDKClass = SDKOppo


class LJPayment(BasePayment):
	SDKClass = SDKLJ


class CoolPadPayment(BasePayment):
	SDKClass = SDKCoolPad


class LenovoPayment(BasePayment):
	SDKClass = SDKLenovo


class SinaPayment(BasePayment):
	SDKClass = SDKSina


class OuwanPayment(BasePayment):
	SDKClass = SDKOuwan


class Ouwan_blbxzPayment(BasePayment):
	SDKClass = SDKOuwan_blbxz


class GioneeCreate(web.RequestHandler):
	@coroutine
	def post(self):
		ret = yield SDKGionee.createCallback(self, False)
		self.write(ret)


class GioneePayment(BasePayment):
	SDKClass = SDKGionee


class VivoCreate(web.RequestHandler):
	@coroutine
	def post(self):
		ret = yield SDKVivo.createCallback(self, False)
		self.write(ret)


class VivoPayment(BasePayment):
	SDKClass = SDKVivo


class ApplePayment(BasePayment):
	SDKClass = SDKApple


class QQPayment(BasePayment):
	SDKClass = SDKQQ


class WXPayment(BasePayment):
	SDKClass = SDKWX


class YijiePayment(BasePayment):
	SDKClass = SDKYijie


class MeizuCreate(web.RequestHandler):
	@coroutine
	def post(self):
		ret = yield SDKMeizu.createCallback(self, False)
		self.write(ret)


class MeizuPayment(BasePayment):
	SDKClass = SDKMeizu


class TTPayment(BasePayment):
	SDKClass = SDKTT


class LBPayment(BasePayment):
	SDKClass = SDKLB


class PywPayment(BasePayment):
	SDKClass = SDKPyw


class LsPayment(BasePayment):
	SDKClass = SDKLs


class YwPayment(BasePayment):
	SDKClass = SDKYw


class TcPayment(BasePayment):
	SDKClass = SDKTc


class QuickPayment(BasePayment):
	SDKClass = SDKQuick


class MofangIFPayment(BasePayment):
	SDKClass = SDKMofangIF


class MofangIYPayment(BasePayment):
	SDKClass = SDKMofangIY


class MofangAFPayment(BasePayment):
	SDKClass = SDKMofangAF


class MofangAYPayment(BasePayment):
	SDKClass = SDKMofangAY

class ZhuodongPayment(BasePayment):
	SDKClass = SDKZhuodong

class LunplayPayment(BasePayment):
	SDKClass = SDKLunplay

class LunplayVNPayment(BasePayment):
	SDKClass = SDKLunplayVN

class LunplayKRPayment(BasePayment):
	SDKClass = SDKLunplayKR

class LunplayENPayment(BasePayment):
	SDKClass = SDKLunplayEN

class LunplayGiftPayment(BasePayment):
	SDKClass = SDKLunplayGift

class KaisaPayment(BasePayment):
	SDKClass = SDKKaisa

class XiaoYPayment(BasePayment):
	SDKClass = SDKXiaoY

class Application(web.Application):
	def __init__(self):
		# create order
		SDKUC.initHttpClient()
		SDKGionee.initHttpClient()
		SDKVivo.initHttpClient()
		SDKApple.initHttpClient()
		SDKMeizu.initHttpClient()
		SDKMofangIF.initHttpClient()
		SDKMofangIY.initHttpClient()
		SDKMofangAF.initHttpClient()
		SDKMofangAY.initHttpClient()
		SDKZhuodong.initHttpClient()
		SDKLunplay.initHttpClient()
		SDKTJGame.initHttpClient()

		SDKQQ.initInGameServer()
		SDKWX.initInGameServer()

		handlers = [
			(r"/uc/create", UCCreate),
			(r"/uc/payment", UCPayment),

			(r"/baidu/payment", BaiduPayment),
			(r"/360/payment", QH360Payment),
			(r"/mi/payment", MiPayment),
			(r"/mi/blbxz/payment", Mi_blbxzPayment),
			(r"/huawei/payment", HuaweiPayment),
			(r"/oppo/payment", OppoPayment),
			(r"/lj/payment", LJPayment),
			(r"/coolpad/payment", CoolPadPayment),
			(r"/lenovo/payment", LenovoPayment),
			(r"/sina/payment", SinaPayment),
			(r"/ouwan/payment", OuwanPayment),

			(r"/gionee/create", GioneeCreate),
			(r"/gionee/payment", GioneePayment),

			(r"/vivo/create", VivoCreate),
			(r"/vivo/payment", VivoPayment),

			(r"/apple/payment", ApplePayment),

			(r"/qq/payment", QQPayment),
			(r"/wx/payment", WXPayment),

			(r"/yijie/payment", YijiePayment),
			(r"/mz/create", MeizuCreate),
			(r"/mz/payment", MeizuPayment),
			(r"/tt/payment", TTPayment),
			(r"/lb/payment", LBPayment),
			(r"/pyw/payment", PywPayment),
			(r"/ls/payment", LsPayment),
			(r"/yw/payment", YwPayment),
			(r"/tc/payment", TcPayment),
			(r"/quick/payment", QuickPayment),

			(r"/mofang_af/payment", MofangAFPayment),
			(r"/mofang_iy/payment", MofangIYPayment),
			(r"/mofang_if/payment", MofangIFPayment),
			(r"/mofang_ay/payment", MofangAYPayment),


			(r"/zd/payment", ZhuodongPayment),
			(r"/lp/payment", LunplayPayment),
			(r"/lp_vn/payment", LunplayVNPayment),
			(r"/lp_kr/payment", LunplayKRPayment),
			(r"/lp_en/payment", LunplayENPayment),
			(r"/lp_gift/payment", LunplayGiftPayment),

			(r"/ks/payment", KaisaPayment),
			(r"/xy51/payment", XiaoYPayment),

			(r"/test/create", TestCreate),
			(r"/test/payment", TestPayment),

			(r"/tjgame/create", TJGameCreate),
			(r"/tjgame/payment", TJGamePayment),
		]
		settings = {
			"autoreload": False,
		}
		web.Application.__init__(self, handlers, **settings)
