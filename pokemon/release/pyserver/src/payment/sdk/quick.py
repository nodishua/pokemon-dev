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
import xml.etree.ElementTree as ET


class SDKQuick(SDKBase):
    Channel = 'quick'
    ReturnOK = 'SUCCESS'
    ReturnErr = 'FAILURE'

    @classmethod
    def parseData(cls, cfg, data):
        d = dict(urlparse.parse_qsl(data))

        key = cfg['callback_key']
        dd = SDKQuick.decode(d['nt_data'], key)
        dd = SDKQuick.makedict(dd)
        logger.info('channel `{schannel}` ch_account `{channel_uid}` status `{status}` order `{order_no}` {amount} coming'.format(schannel=cls.Channel, **dd))
        validSign = '{nt_data}{sign}{callbackkey}'.format(callbackkey=key, **d)
        validSign = hashlib.md5(validSign).hexdigest()
        
        if validSign != d['md5Sign']:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')

        return dd

    @classmethod
    def getOrderID(cls, d):
        return d['order_no']

    @classmethod
    def getOrderResult(cls, d):
        return True if d['status'] == '0' else False

    @classmethod
    def getClientInfo(cls, d):
        return d['extras_params']

    @classmethod
    def getOrderAmount(cls, d):
        return float(d['amount'])

    @classmethod
    def getOrderErrMsg(cls, d):
        return d['status']

    @staticmethod
    def decode(str, key):
        l = []
        for i in str.split('@'):
            if i:
                l.append(int(i))
        ret = ''
        for i in xrange(0,len(l)):
            c = l[i] - (0xff & ord(key[i % len(key)]))
            ret += chr(c) 
        return ret

    @staticmethod
    def makedict(xml):
        root = ET.fromstring(xml)[0]
        ret = {}
        for child in root:
            ret[child.tag] = child.text

        return ret
