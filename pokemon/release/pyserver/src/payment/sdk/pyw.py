#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import json
import time
import hashlib


class SDKPyw(SDKBase):
    Channel = 'pyw'
    ReturnOK = '{"ack":200,"msg":"Ok"}'
    ReturnErr = '{"ack":0,"msg":"Err"}'

    @classmethod
    def parseData(cls, cfg, data):
        d = json.loads(data, object_hook=toUTF8Dict)

        logger.info('channel `{cp_channel}` ch_account `{cp_param}` status `True` order `{ch_orderid}` {amount} coming'.format(cp_channel=cls.Channel, **d))

        validSign = '{apiSecret}{cp_orderid}{ch_orderid}{amount}'.format(apiSecret=cfg['appsecret'], **d)
        validSign = hashlib.md5(validSign).hexdigest()

        if validSign != d['sign']:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')

        return d

    @classmethod
    def getOrderID(cls, d):
        return d['ch_orderid']

    @classmethod
    def getOrderResult(cls, d):
        return True

    @classmethod
    def getClientInfo(cls, d):
        dd = json.loads(d['cp_param'], object_hook=toUTF8Dict)
        return dd['info']

    @classmethod
    def getOrderAmount(cls, d):
        return float(d['amount'])

    @classmethod
    def getOrderErrMsg(cls, d):
        return 'none'

