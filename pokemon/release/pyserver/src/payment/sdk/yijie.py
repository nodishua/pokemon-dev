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


class SDKYijie(SDKBase):
    Channel = 'yijie'
    ReturnOK = 'SUCCESS'
    ReturnErr = 'FAILURE'

    @classmethod
    def parseData(cls, cfg, data):
        d = dict(urlparse.parse_qsl(data))
        logger.info('channel `{channel}` ch_account `{uid}` status `{st}` order `{tcd}` {fee} coming'.format(channel=cls.Channel, **d))
        validSign = 'app={app}&cbi={cbi}&ct={ct}&fee={fee}&pt={pt}&sdk={sdk}&ssid={ssid}&st={st}&tcd={tcd}&uid={uid}&ver={ver}{appsecret}'.format(appsecret=cfg['appsecret'], **d)
        validSign = hashlib.md5(validSign).hexdigest()
        
        if validSign != d['sign']:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')

        return d

    @classmethod
    def getOrderID(cls, d):
        return d['tcd']

    @classmethod
    def getOrderResult(cls, d):
        return True if d['st'] == '1' else False

    @classmethod
    def getClientInfo(cls, d):
        return d['cbi']

    @classmethod
    def getOrderAmount(cls, d):
        return float(d['fee']) / 100

    @classmethod
    def getOrderErrMsg(cls, d):
        return d['st']

