#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase
from payment.clientdata import ClientData

import json
import time
import hashlib
import urlparse

RechargeMap = {
    1: 30,
    2: 88,
    3: 648,
    4: 328,
    5: 198,
    6: 98,
    7: 60,
    8: 30,
    9: 6,

    101: 1,
    102: 6,
    103: 12,
    104: 18,
    105: 25,
    106: 30,
    107: 60,
    108: 98,
    109: 128,
    110: 168,
    111: 198,
    112: 328,
    113: 648,
}

class SDKTc(SDKBase):
    Channel = 'tc'
    ReturnOK = '{"ret":0,"data":"Ok"}'
    ReturnErr = '{"ret":-1,"data":"Err"}'

    @classmethod
    def parseData(cls, cfg, data):
        d = dict(urlparse.parse_qsl(data))
        logger.info('channel `{channel}` ch_account `{user_id}` status `True` order `{sevenga_order_id}` coming'.format(channel=cls.Channel, **d))
        if float(d.get('amount', 0)) < 2.0:
            raise Exception('amount error')

        # 天赐签名没有规定顺序，应该按照请求数据顺序
        querys = data.split('&')
        validSign = ''
        for i in xrange(0, len(querys)-1):
            validSign = validSign + querys[i] + '&'
        validSign = validSign + 'secret_key=%s'%cfg['appsecret']
        validSign = hashlib.sha1(validSign).hexdigest()

        if validSign != d['sign']:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')

        return d

    @classmethod
    def getOrderID(cls, d):
        return d['sevenga_order_id']

    @classmethod
    def getOrderResult(cls, d):
        return True

    @classmethod
    def getClientInfo(cls, d):
        cdata = ClientData(d['game_extra'])
        if RechargeMap[cdata.rechargeID] != int(d['amount']):
            logger.error('%s %s recharge amount error', cls.Channel, cls.getOrderID(d))
            return None
        return d['game_extra']

    @classmethod
    def getOrderAmount(cls, d):
        # 天赐回调没有这个
        return float(d['amount']) if 'amount' in d else None

    @classmethod
    def getOrderErrMsg(cls, d):
        return 'none'

