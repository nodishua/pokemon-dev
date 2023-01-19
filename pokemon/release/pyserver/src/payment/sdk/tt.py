#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import json
import time
import base64
import urllib
import hashlib
import urlparse


class SDKTT(SDKBase):
    Channel = 'tt'
    ReturnOK = '{"head":{"result":"0", "message":"success"}}'
    ReturnErr = '{"head":{"result":"1", "message":"failure"}}'

    @classmethod
    def parseData(cls, cfg, data):
        data, sdkSign = data
        # 先做 urldecode,字符串格式
        data = urllib.unquote_plus(data)
        d = json.loads(data, object_hook=toUTF8Dict)
        logger.info('channel `{channel}` ch_account `{uid}` status `{payResult}` order `{sdkOrderId}` {payFee} coming'.format(channel=cls.Channel, **d))
        validSign = '{data}{appsecret}'.format(appsecret=cfg['appsecret'], data=data)
        #validSign = validSign.replace('\\','')
        validSign = hashlib.md5(validSign).digest()
        validSign = base64.b64encode(validSign)

        if validSign != sdkSign:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')

        return d

    @classmethod
    def getOrderID(cls, d):
        return d['sdkOrderId']

    @classmethod
    def getOrderResult(cls, d):
        return True if d['payResult'] == '1' else False

    @classmethod
    def getClientInfo(cls, d):
        return d['exInfo']

    @classmethod
    def getOrderAmount(cls, d):
        return float(d['payFee'])

    @classmethod
    def getOrderErrMsg(cls, d):
        return d['payResult']

