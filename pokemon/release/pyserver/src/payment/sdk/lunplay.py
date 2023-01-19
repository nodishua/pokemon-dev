#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine
from payment.sdk.base import SDKBase
from payment.clientdata import ClientData

import json
import hashlib
import urlparse
import base64

# 价格台币
TWRechargeMap = {
    1: 170,
    2: 430,

    102: 33,
    103: 70,
    104: 100,
    105: 130,
    106: 170,
    107: 290,
    108: 490,
    109: 670,
    110: 870,
    111: 990,
    112: 1690,
    113: 3290,

    4101: 33,
    4102: 70,
    4103: 100,
    4104: 130,
    4105: 170,
    4106: 290,
    4107: 430,
    4108: 490,
    4109: 670,
    4110: 870,
    4111: 990,
    4112: 1690,
    4113: 3290,
}

# lp_en, 价格美金
ENRechargeMap = {
    1: 4.99,
    2: 12.99,

    102: 0.99,
    103: 1.99,
    104: 2.99,
    105: 3.99,
    106: 4.99,
    107: 8.99,
    108: 14.99,
    109: 19.99,
    110: 25.99,
    111: 29.99,
    112: 49.99,
    113: 99.99,

    2101: 0.99,
    2102: 1.99,
    2103: 2.99,
    2104: 3.99,
    2105: 4.99,
    2106: 8.99,
    2107: 12.99,
    2108: 14.99,
    2109: 19.99,
    2110: 25.99,
    2111: 29.99,
    2112: 49.99,
    2113: 99.99,
}

class SDKLunplay(SDKBase):
    Channel = 'lp'
    ReturnOK = json.dumps({"code": 0, "content": "充值成功"})
    ReturnErr = json.dumps({"code": -255, "content": "fail"})
    HttpClient = None
    RechargeMap = TWRechargeMap

    @classmethod
    def parseData(cls, cfg, data):
        d = dict(urlparse.parse_qsl(data))
        logger.info('channel `{channel}` agent `{agent}` passport `{passport}` server `{server}` order `{order}` money `{money}` sign `{sign}` time `{time}` param `{param}` goodid `{goodid}` repro `{repro}`'.format(channel=cls.Channel, repro=d.get('rePro', 0), **d))

        if 'rePro' in d:
            sign = d['passport'] + d['order'] + cfg['key2'] + d['server'] + d['time'] + d['agent'] + d['money'] + d['goodid'] + d['rePro']
        else:
            sign = d['passport'] + d['order'] + cfg['key2'] + d['server'] + d['time'] + d['agent'] + d['money'] + d['goodid']
        sign = hashlib.md5(sign).hexdigest()

        if sign != d['sign']:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')

        return d

    @classmethod
    def getOrderResult(cls, d):
        return True

    @classmethod
    def getOrderID(cls, d):
        return d['order']

    @classmethod
    def getClientInfo(cls, d):
        if d['param'][0] == '[' and d['param'][-1] == ']':
             data = d['param']
        else:
            data = base64.b64decode(d['param'])

        cdata = ClientData(data)

        if float(d['money']) != float(cls.RechargeMap[cdata.rechargeID]):
            logger.error('%s %s recharge amount error', cls.Channel, cls.getOrderID(d))
            return None
        return data

    @classmethod
    def getOrderAmount(cls, d):
        return float(d['money'])

    @classmethod
    def getOrderErrMsg(cls, d):
        return ''

    @classmethod
    def parseDataReProToGame(cls, data):
        d = dict(urlparse.parse_qsl(data))
        rePro = int(d.get('rePro', 0))
        if rePro < 0 or rePro > 100:
            logger.warning('%s %s rePro error, got %s', cls.Channel, d['order'], rePro)
            rePro = 0
        dd = {
            'rePro': rePro,
        }
        return dd

class SDKLunplayVN(SDKLunplay):
    Channel = 'lp_vn'
    ReturnOK = json.dumps({"code": 0, "content": "充值成功"})
    ReturnErr = json.dumps({"code": -255, "content": "fail"})
    HttpClient = None

class SDKLunplayKR(SDKLunplay):
    Channel = 'lp_kr'
    ReturnOK = json.dumps({"code": 0, "content": "充值成功"})
    ReturnErr = json.dumps({"code": -255, "content": "fail"})
    HttpClient = None
    RechargeMap = TWRechargeMap

class SDKLunplayEN(SDKLunplay):
    Channel = 'lp_en'
    ReturnOK = json.dumps({"code": 0, "content": "充值成功"})
    ReturnErr = json.dumps({"code": -255, "content": "fail"})
    HttpClient = None
    RechargeMap = ENRechargeMap

class SDKLunplayGift(SDKLunplay):
    Channel = 'lp_gift'
    ReturnOK = json.dumps({"code": 0, "msg": "充值成功"})
    ReturnErr = json.dumps({"code": -255, "msg": "fail"})
    HttpClient = None
    ClientInfo = ['000000000000000000000000','000000000000000000000000',"",0,0,0]

    @classmethod
    def parseData(cls, cfg, data):
        d = dict(urlparse.parse_qsl(data))
        logger.info('channel `{channel}` ck `{ck}` t `{t}` itemCode `{itemCode}` orderID `{orderID}` passport `{passport}` gameCode `{gameCode}` money `{money}` giftID `{giftID}`'.format(channel=cls.Channel, **d))
        ck = d['itemCode'] + d['orderID'] + d['t'] + cfg['key2'] + d['passport'] + d['gameCode'] + d['money'] + d['giftID']
        ck = hashlib.md5(ck).hexdigest()

        if ck != d['ck']:
            logger.error('%s ck error %s', cls.Channel, data)
            raise Exception('ck error')
        return d

    @classmethod
    def getOrderID(cls, d):
        return d['orderID']

    @classmethod
    def getClientInfo(cls, d):
        return cls.ClientInfo

    @classmethod
    def getReturnOK(cls, d):
        ret = {"code": 3, "msg": "查询成功"}
        ret['cardNum'] = d
        return json.dumps(ret)

