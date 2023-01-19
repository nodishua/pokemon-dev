#!/usr/bin/python
# -*- coding: utf-8 -*-

import copy
import hashlib
import datetime
import binascii

from bson.objectid import ObjectId


def calc_md5(pwd):
	md5 = hashlib.md5()
	md5.update(pwd)
	return md5.hexdigest()


def datetime2str(d, f='S'):
    if f == 'S':
        return d.strftime("%Y-%m-%d %H:%M:%S")
    elif f == 'M':
        return d.strftime("%Y-%m-%d %H:%M")
    elif f == 'H':
        return d.strftime("%Y-%m-%d %H")
    elif f == 'd':
        return d.strftime("%Y-%m-%d")

def str2datetime(s, f='S'):
    if f == 'S':
        return datetime.datetime.strptime(s, "%Y-%m-%d %H:%M:%S")
    elif f == 'd':
        return datetime.datetime.strptime(s, "%Y-%m-%d")

def hexlifyDictField(dl):
    dlc = copy.deepcopy(dl)
    if isinstance(dlc, list):
        for d in dlc:
        	_hexlify(d)
    else:
        _hexlify(dlc)
    return dlc

def _hexlify(d):
    for k, v in d.items():
        if isinstance(v, ObjectId):
            d[k] = binascii.hexlify(v.binary)
        elif k in ('id', 'account_id', 'union_db_id', 'db_id', 'role_db_id', 'record_id') and v:
            d[k] = binascii.hexlify(v)


############
# statistics helper
############

# RechargeMap = [0, 0, 0, 648, 328, 198, 98, 60, 30, 6, 0, 0, 0, 0, 0, 0, 0]
RechargeMap = {
    1: 0,
    2: 0,
    3: 648,
    4: 328,
    5: 198,
    6: 98,
    7: 60,
    8: 30,
    9: 6,

    1001: 648,
    1002: 328,
    1003: 198,
    1004: 98,
    1005: 60,
    1006: 30,
    1007: 6,
}
TWRechargeMap = [0, 0, 0, 99.99, 48.99, 28.99, 14.99, 9.99, 4.99, 0.99, 0, 0, 0, 0, 0, 0, 0]
ENRechargeMap = [0, 0, 0, 99.99, 48.99, 28.99, 14.99, 9.99, 4.99, 0.99, 0, 0, 0, 0, 0, 0, 0]
VNRechargeMap = {
    1: 0,
    2: 0,
    3: 99.99,
    4: 48.99,
    5: 28.99,
    6: 14.99,
    7: 9.99,
    8: 4.99,
    9: 0.99,

    21:     0.99,
    22:     1.99,
    23:     4.99,
    24:     9.99,
    25:     24.99,
    26:     49.99,
    27:     99.99,

    31:     0.42,
    32:     0.84,
    33:     1.26,
    34:     2.10,
    35:     2.52,
    36:     4.20,
    37:     8.40,
    38:     12.60,
    39:     21.00,
    40:     42.00,
    41:     84.00,
    42:     210.00,
    43:     420.00,
}
THRechargeMap = {
    1: 0,
    2: 0,
    3: 99.99,
    4: 48.99,
    5: 28.99,
    6: 14.99,
    7: 9.99,
    8: 4.99,
    9: 0.99,

    # MOL支付，结算单位泰铢，等价的美元
    # 货币单位   档位 对应ID    泰铢  钻石数 美元
    # 泰铢    50  com.go.mol.4001 50  80  1.40
    #   60   com.go.mol.4002    60  100 1.68
    #   90   com.go.mol.4003    90  150 2.52
    #   100  com.go.mol.4004    100 170 2.80
    #   150  com.go.mol.4005    150 250 4.19
    #   200  com.go.mol.4006    200 335 5.59
    #   300  com.go.mol.4007    300 500 8.39
    #   500  com.go.mol.4008    500 840 13.98
    #   1000     com.go.mol.4009    1000    1680    27.96
    #   3500     com.go.mol.4010    3500    5880    97.87
    #   5000     com.go.mol.4011    5000    8400    139.82
    51:     1.40,
    52:     1.68,
    53:     2.52,
    54:     2.80,
    55:     4.19,
    56:     5.59,
    57:     8.39,
    58:     13.98,
    59:     27.96,
    60:     97.87,
    61:     139.82,
}
# orders {xxx: PayOrder.Model}

def sumRecharges(orders, language):
    import framework
    language = framework.__language__
    if language == 'cn':
        recharges = [RechargeMap[d['recharge_id']] for d in orders.itervalues() if d['recharge_id'] in RechargeMap]
    elif language == 'tw':
        recharges = [TWRechargeMap[d['recharge_id']] for d in orders.itervalues()]
    elif language == 'en':
        recharges = [ENRechargeMap[d['recharge_id']] for d in orders.itervalues()]
    elif language == 'vn':
        recharges = [VNRechargeMap[d['recharge_id']] for d in orders.itervalues() if d['recharge_id'] in VNRechargeMap]
    elif language == 'th':
        recharges = [THRechargeMap[d['recharge_id']] for d in orders.itervalues() if d['recharge_id'] in THRechargeMap]

    s = sum(recharges)
    # 保留小数点后2位
    if isinstance(s, float):
        s = round(s, 2)
    return s

RechargeConvertMap = {
    'cn': RechargeMap,
    'tw': TWRechargeMap,
    'en': ENRechargeMap,
    'vn': VNRechargeMap,
    'th': THRechargeMap
}
def convertRecharge(recharge_id, language):
    return RechargeConvertMap[language][recharge_id]

# TODO: 混服后会影响到server_key
def getServerArea(servKey):
    s = filter(lambda c: c.isdigit(), servKey)
    try:
        return int(s)
    except:
        return None

def getServerLanguageByKey(servKey):
    import framework
    return framework.__language__

    if servKey.find('_qq') >= 0:
        return 'cn'
    try:
        serverLanguage = servKey.split('_')[1][:2]
    except IndexError as e:
        if servKey == "game":
            return 'cn'
        else:
            raise e
    return serverLanguage

# mofang_iy, mofang_ay: en
# mofang_if, mofang_af, mofang_google: tw
# tutu: en
# funtap_ios, funtap_android: vn
def getServerLanguageByChannel(channel, subChannel):
    import framework
    return framework.__language__

    if channel.find('mofang') >= 0:
        # mofang_af, mofang_iy
        # channel无法区分，得靠subChannel
        if subChannel[-1] == 'y':
            return 'en'
        elif subChannel[-2:] == 'th':
            return 'th'
        return 'tw'
    elif channel.find('funtap') >= 0:
        return 'vn'
    elif channel == 'tutu':
        return 'en'
    elif channel.find('mrgl') >= 0:
        return 'en'
    return 'cn'

def slimOrder(order):
    return {
        '_id': order._id,
        # 'account_id': order.account_id,
        'server_key': order.server_key,
        # 'role_id': order.role_id,
        # 'time': order.time,
        # 'channel': order.channel,
        'recharge_id': order.recharge_id,
    }


# serv key name helper
# copy from framework.distributed.helper
from framework.distributed.helper import serv_key2domains, node_domains2key

ServNameKeyMap = {
    'game.dev.1': 'game_dev1',
    'game.dev.2': 'game_dev2',
    'game.dev.3': 'game_dev3',
    'game.dev.4': 'game_dev4',
    'game.dev.5': 'game_dev5',
    'game.dev.6': 'game_dev6',

    'game_dev1': 'game.dev.1',
    'game_dev2': 'game.dev.2',
    'game_dev3': 'game.dev.3',
    'game_dev4': 'game.dev.4',
    'game_dev5': 'game.dev.5',
    'game_dev6': 'game.dev.6',
}

def servName2ServKey(servName):
    if servName in ServNameKeyMap:
        return ServNameKeyMap[servName]
    domains = serv_key2domains(servName)
    return node_domains2key(domains)

def servKey2ServName(nodekey):
    if nodekey in ServNameKeyMap:
        return ServNameKeyMap[nodekey]
    servName = ''
    domains = nodekey.split('.')
    if len(domains) == 3:
        servName = '%s_%s%02d' % (domains[0], domains[1], int(domains[2]))
    elif len(domains) == 2:
        servName = '%s_qq%02d' % (domains[0], int(domains[1]))
    else:
        raise Exception('error nodekey %s', nodekey)
    return servName

def roleKey2RedisZKey(roleKey):
    return '_'.join((roleKey[0], str(roleKey[1])))

def redisZKey2RoleKey(key):
    domains = key.split('_')
    return (domains[0], int(domains[1]))

def is_key(key):
    if key.find('_') == -1:
        return True
    return False

def objectid2str(_id):
    if isinstance(_id, ObjectId):
        s = binascii.hexlify(_id.binary)
        return s
    return _id

def str2objectid(s):
    assert len(s) == 24, '%s length is not 24'% s
    return ObjectId(s)

# copy from framework.csv.MergeServ
class MergeServ(object):
    DestServMerge = {} # {gamemerge.1: [game.1, ...]}
    DestServAreas = {} # {gamemerge.1: [1, 2, 3]}
    SrcServMerge = {} # {game.1 : gamemerge.1}
    ServCfg = {} # {gamemerge.1: cfg}

    @classmethod
    def classInit(cls):
        cls.DestServMerge = {}
        cls.DestServAreas = {}
        cls.SrcServMerge = {}
        cls.ServCfg = {}
        mergemap = {}

        mergesDestL = []
        for idx in sorted(csv.server.merge.keys()):
            cfg = csv.server.merge[idx]
            if cfg.realityMerge != 1:
                continue
            mergemap[cfg.destServer] = cfg.servers
            cls.ServCfg[cfg.destServer] = cfg
            mergesDestL.append(cfg.destServer)

        def destServ2SrcServ(dest):
            srcServ = mergemap[dest]
            servs = []
            for serv in srcServ:
                if serv in mergemap:
                    if serv != dest:
                        servs.extend(destServ2SrcServ(serv))
                    else:
                        servs.append(serv)
                else:
                    servs.append(serv)
            return servs

        for dest in mergesDestL:
            srcs = destServ2SrcServ(dest)
            cls.DestServMerge[dest] = srcs
            cls.DestServAreas[dest] = [int(key.split('.')[-1]) for key in srcs]
            for src in srcs:
                cls.SrcServMerge[src] = dest

    @classmethod
    def getMergeServKey(cls, srcKey):
        return cls.SrcServMerge.get(srcKey, srcKey)

    @classmethod
    def getSrcServKeys(cls, mergeKey):
        return cls.DestServMerge.get(mergeKey, [mergeKey])

    @classmethod
    def getSrcServAreas(cls, mergeKey):
        return cls.DestServAreas.get(mergeKey, [int(mergeKey.split('.')[-1])])

    @classmethod
    def getServCfg(cls, servKey):
        return cls.ServCfg.get(servKey, None)

    @classmethod
    def inSubServer(cls, destKey, srcKey):
        return srcKey in cls.DestServMerge.get(destKey, [])

    @classmethod
    def isServMerged(cls, servKey):
        if servKey not in cls.DestServMerge:
            return False
        srcKeys = cls.DestServMerge.get(servKey)
        if len(srcKeys) > 1 or srcKeys[0] != servKey:
            return True
        return False

    @classmethod
    def slimServNames(cls, servNames):
        from framework.distributed.helper import servName2ServKey

        key2name = {}
        keys = set()
        for name in servNames:
            key = servName2ServKey(name)
            key2name[key] = name
            keys.add(cls.getMergeServKey(key))
        retKeys = []
        for key in keys:
            retKeys.append(cls.getSrcServKeys(key)[0])
        retNames = [key2name[key] for key in retKeys]
        return retNames
