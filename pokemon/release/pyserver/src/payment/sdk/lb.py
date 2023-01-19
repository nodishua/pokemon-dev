#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import json
import time
import urllib
import hashlib
import urlparse


class SDKLB(SDKBase):
    Channel = 'lb'
    ReturnOK = 'success'
    ReturnErr = 'error'

    @classmethod
    def parseData(cls, cfg, data):
        # 验证签名之后再解码
        d = dict(urlparse.parse_qsl(data))
        logger.info('channel `{channel}` ch_account `{username}` status `True` order `{orderid}` {amount} coming'.format(channel=cls.Channel, **d))
        validSign = 'orderid={orderid}&username={username}&gameid={gameid}&roleid={roleid}&serverid={serverid}&paytype={paytype}&amount={amount}&paytime={paytime}&attach={attach}&appkey={appkey}'.format(appkey=cfg['appkey'], **d)
        validSign = hashlib.md5(validSign).hexdigest()

        if validSign != d['sign']:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')

        data = urllib.unquote(data).encode('utf8')
        d = dict(urlparse.parse_qsl(data))
        return d

    @classmethod
    def getOrderID(cls, d):
        return d['orderid']

    @classmethod
    def getOrderResult(cls, d):
        return True

    @classmethod
    def getClientInfo(cls, d):
        return d['attach']

    @classmethod
    def getOrderAmount(cls, d):
        return int(d['amount'])

    @classmethod
    def getOrderErrMsg(cls, d):
        return 'none'

