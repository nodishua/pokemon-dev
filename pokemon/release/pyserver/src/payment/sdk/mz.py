#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework import nowtime_t
from framework.log import logger
from framework.helper import toUTF8Dict
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase
from payment.sdk import channelOrderID
from payment.clientdata import ClientData

import os
import json
import time
import hashlib
import binascii
import urlparse


class SDKMeizu(SDKBase):
    Channel = 'mz'
    ReturnOK = '{"code": "200", "message":"", "value":"", "redirect":""}'
    ReturnErr = '{"code": "120014", "message":"", "value":"", "redirect":""}'

    @classmethod
    def parseData(cls, cfg, data):
        # print data
        d = dict(urlparse.parse_qsl(data))
        logger.info('channel `{channel}` ch_account `{uid}` status `{trade_status}` order `{order_id}` {total_price} coming'.format(channel=cls.Channel, **d))

        sign = hashlib.md5("app_id={app_id}&buy_amount={buy_amount}&cp_order_id={cp_order_id}&create_time={create_time}&notify_id={notify_id}&notify_time={notify_time}&order_id={order_id}&partner_id={partner_id}&pay_time={pay_time}&pay_type={pay_type}&product_id={product_id}&product_per_price={product_per_price}&product_unit=&total_price={total_price}&trade_status={trade_status}&uid={uid}&user_info={user_info}:{appSecret}".format(appSecret=cfg['appsecret'],**d)).hexdigest()
        if sign != d['sign']:
            logger.error('%s sign error %s', cls.Channel, data)
            raise Exception('sign error')
        return d

    @classmethod
    def getOrderID(cls, d):
        return d['order_id']

    @classmethod
    def getOrderResult(cls, d):
        return True if d['trade_status'] == '3' else False

    @classmethod
    def getClientInfo(cls, d):
        return d['user_info']

    @classmethod
    def getOrderAmount(cls, d):
        return d['total_price']

    @classmethod
    def getOrderErrMsg(cls, d):
        return d['trade_status']

    @classmethod
    @coroutine
    def fetchChannelOrderID(cls, cfg, d, myOrderID):
        # 无需通知到sdk服务器
        d['appid'] = cfg['appid']
        d['appsecret'] = cfg['appsecret']
        raise Return((None, d))

    @classmethod
    def makeReturnDict(cls, myOrderID, d):
        accountId = d['account']
        recharge_id = d['productid']
        servkey = d['servkey']
        rid = d['role']
        create_time = long(nowtime_t())

        total_price = long(d['amount'])
        product_subject = '购买%d颗钻石' % (total_price *10)
        user_info = (accountId, rid, servkey, recharge_id)
        user_info = json.dumps(user_info)
        #create sign
        ret = {
            'app_id': d['appid'],
            'buy_amount': "1",
            'cp_order_id': myOrderID,
            'create_time': create_time,
            'pay_type': "0",
            'product_body': "",
            'product_id': recharge_id,
            'product_per_price': total_price,
            'product_subject': product_subject,
            'product_unit': "",
            'total_price': total_price,
            'uid': d['channelid'],
            'user_info': user_info,
        }

        sign = hashlib.md5('app_id={app_id}&buy_amount={buy_amount}&cp_order_id={cp_order_id}&create_time={create_time}&pay_type={pay_type}&product_body={product_body}&product_id={product_id}&product_per_price={product_per_price}&product_subject={product_subject}&product_unit={product_unit}&total_price={total_price}&uid={uid}&user_info={user_info}:{AppSecret}'.format(AppSecret=d['appsecret'], **ret)).hexdigest()
        ret['sign'] = sign
        ret['sign_type'] = 'md5'
        return ret



