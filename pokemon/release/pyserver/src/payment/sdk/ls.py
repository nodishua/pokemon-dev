#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import json
import time
import hashlib
import urlparse


class SDKLs(SDKBase):
    Channel = 'ls'
    ReturnOK = {"errno": 1000}
    ReturnErr = {"errno": -1008}

    @classmethod
    def parseData(cls, cfg, data):
        d = dict(urlparse.parse_qsl(data))
        
        # paychannel有可能为空，防止keyerror
        d['payChannel'] = d['payChannel'] if 'payChannel' in d else ''
        # amount 单位是分。
        logger.info('channel `{channel}` ch_account `{uid}` status `True` order `{orderId}` {amount} coming'.format(channel=cls.Channel, **d))
        validSign = '{game}{orderId}{amount}{uid}{zone}{goodsId}{payTime}{payChannel}{payExt}#{appsecret}'.format(appsecret=cfg['appsecret'], **d)
        validSign = hashlib.md5(validSign).hexdigest()
        
        if validSign != d['sign']:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')

        return d

    @classmethod
    def getOrderID(cls, d):
        return d['orderId']

    @classmethod
    def getOrderResult(cls, d):
        return True

    @classmethod
    def getClientInfo(cls, d):
        return d['payExt']

    @classmethod
    def getOrderAmount(cls, d):
        return float(d['amount']) / 100

    @classmethod
    def getOrderErrMsg(cls, d):
        return 'none'

    @classmethod
    def getReturnOK(cls, d):
        ret = {'errno':1000, 'errmsg':''}
        ret['data'] = {
            'orderId': d['orderId'],
            'amount': d['amount'],
            'game': d['game'],
            'zone': d['zone'],
            'uid': d['uid']
        }

        return json.dumps(ret)

