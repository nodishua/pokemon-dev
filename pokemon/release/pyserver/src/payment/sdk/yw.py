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


class SDKYw(SDKBase):
    Channel = 'yw'
    ReturnOK = '1'
    ReturnErr = '103'

    @classmethod
    def parseData(cls, cfg, data):
        d = dict(urlparse.parse_qsl(data))
        # amount 单位是分。
        logger.info('channel `{channel}` ch_account `{openid}` status `{status}` order `{ordernum}` {amount} coming'.format(channel=cls.Channel, **d))
        # 防止errdesc为空
        errdescmsg = d['errdesc'] if 'errdesc' in d else ''

        validSign = '{serverid}|{custominfo}|{openid}|{ordernum}|{status}|{paytype}|{amount}|{errdescmsg}|{paytime}|{appkey}'.format(appkey=cfg['appkey'], errdescmsg=errdescmsg, **d)
        validSign = hashlib.md5(validSign).hexdigest()
        
        if validSign != d['sign']:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')

        return d

    @classmethod
    def getOrderID(cls, d):
        return d['ordernum']

    @classmethod
    def getOrderResult(cls, d):
        return d['status'] == '1'

    @classmethod
    def getClientInfo(cls, d):
        return d['custominfo']

    @classmethod
    def getOrderAmount(cls, d):
        return int(d['amount']) / 100

    @classmethod
    def getOrderErrMsg(cls, d):
        # 防止errdesc为空
        return d['errdesc'] if 'errdesc' in d else ''



