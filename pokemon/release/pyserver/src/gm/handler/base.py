# -*- coding: utf-8 -*-

from __future__ import absolute_import

import json
import copy
import binascii
from collections import defaultdict

from tornado.web import RequestHandler
from tornado.web import HTTPError
import tornado.locale

import framework
from framework import *
from framework.log import logger

from ..object.session import Session, SESSION_KEY
from ..object.db import *
from ..object.account import DBAccount
from ..object.archive import DBArchive, DBDailyArchive
from ..object.order import DBOrder
from gm.object.loganalyzer.archive import DBLogRoleArchive
from gm.util import *


class BaseHandler(RequestHandler):
    ChannelCache = {}
    ChannelCacheLastTime = 0
    ServerCache = {}
    ServerCacheLastTime = 0
    AccountPermission = {}
    AccountGMRPCs = {}

    def get_current_user(self):
        sessionID = self.get_secure_cookie(SESSION_KEY)
        if sessionID:
            return Session.getSessionByID(sessionID)
        return None

    def get_user_locale(self):
        if self.current_user and self.current_user.language:
            return tornado.locale.get(self.current_user.language)
        return self.get_browser_locale(default="zh_CN")

    @property
    def messageMap(self):
        return self.application.messageMap

    @property
    def session(self):
        return self.current_user

    @property
    def locale(self):
        return self.get_user_locale()

    def translate(self, text):
        return self.locale.translate(text)

    @property
    def mongo_client(self):
        return self.application.Mongo.client

    @property
    def gameRPCs(self):
        return self.application.gameRPCs

    @property
    def gameShenheRPCs(self):
        return self.application.gameShenheRPCs

    @property
    def dbcAccount(self):
        return self.application.dbcAccount

    @property
    def dbcGM(self):
        return self.application.dbcGM

    @property
    def dbcGift(self):
        return self.application.dbcGift

    @property
    def userGMRPC(self):
        return self.application.console

    def render_page(self, page, **kwargs):
        self.render(
                page,
                user = self.current_user,
                servs = self.servsList,
                channels = self.channelList,
                userLocale = self.language,
                debug = self.debug,
                **kwargs
            )

    @property
    def servsList(self):
        return self.application.servsList

    def write_json(self, data):
        self.write(json.dumps(data))

    def get_json_data(self):
        if self.request.headers["Content-Type"] == "application/json":
            return json.loads(self.request.body)
        return {}

    def setLocalColumns(self, columns):
        locale  = self.language

        if locale == 'en':
            for c in columns:
                titleEN = c['field'].replace('_', '')
                c['title'] = titleEN.upper()
        elif locale == 'vn':
            for c in columns:
                c['title'] = self.translate(unicode(c['title']))
                if '' == c['title']:
                    c['title'] = c['field'].replace('_', '').upper()
        return columns

    @property
    def language(self):
        return framework.__language__

    @property
    def channelCache(self):
        if time.time() - BaseHandler.ChannelCacheLastTime > 1800.0:
            d = {str(x): 2 for x in self.mongo_client.Account.distinct('sub_channel')}
            d.update({str(x): 1 for x in self.mongo_client.Account.distinct('channel')})
            # pyw算分发渠道，没有单接
            # d['pyw'] = 2
            BaseHandler.ChannelCache = d
            BaseHandler.ChannelCacheLastTime = time.time()
        channels = dict(BaseHandler.ChannelCache)
        if self.isTCAccount():
            channels.pop('shuguo', None)
        return channels

    @property
    def channelList(self):
        return sorted(self.channelCache.items(), key=lambda t: (t[1], t[0]))

    @property
    def channelListAndAll(self):
        return [('All', 1)] + self.channelList

    def isTCAccount(self):
        return self.userName in ('admin', 'admin2', 'admin3', 'admin4', 'gmweb',
            'zhang', 'jiang', 'hanyang', 'tc_gm01', 'tc_gm02', 'tc_gm03',
            'tc_gm04', 'tc_gm05', 'tc_gm06', 'tc_gm07', 'tc_gm08',
            'tc_gm09', 'tc_bus01')

    def isShuGuoAccount(self):
        return self.userName.find('shuguo') >= 0

    @property
    def userName(self):
        if self.current_user:
            return self.current_user.name
        return 'none'

    # 判断subChannel
    def getSubChannel(self, channel):
        return channel if self.channelCache.get(channel, 1) == 2 else None

    def defaultDays(self, startDate, endDate, tag=False):
        days = {}
        if isinstance(startDate, datetime.datetime):
            st = startDate
        else:
            st = datetime.datetime.combine(int2date(startDate), datetime.time())
        if isinstance(endDate, datetime.datetime):
            ed = endDate
        else:
            ed = datetime.datetime.combine(int2date(endDate), datetime.time())

        while st <= ed:
            if tag:
                days[date2int(st)] = DBLogRoleArchive(DBLogRoleArchive.defaultDocument(date=date2int(st)))
            else:
                days[date2int(st)] = DBDailyArchive(DBDailyArchive.defaultDocument(date2int(st)))
            st += OneDay
        return days

    def paddingArchiveDays(self, q, days, tag=False): # days: {date: DBDailyArchive,}
        query = {'language': self.language}
        query.update(q)

        for dateInt in days.keys():
            query.update({'date': dateInt})
            if tag:
                archives = DBFind(self.mongo_client, DBLogRoleArchive, query, noCache=True)
            else:
                archives = DBFind(self.mongo_client, DBArchive, query, noCache=True)
            for archive in archives:
                days[dateInt].addRecord(archive)
        return days

    def getDailyArchive(self, days, fix=False):
        # 重新统计
        if fix and self.dbProcess and self.dbProcess.taskDone:
            self.dbProcess.sendTask(('fixDB', days.keys()))

        for dateInt in days.keys():
            if dateInt > todaydate2int():
                continue
            query = {'date': dateInt, 'language': self.language}

            if fix or dateInt == todaydate2int():
                archives = DBFind(self.mongo_client, DBArchive, query, noCache=True)
                dailyArchive = DBFindOrCreate(self.mongo_client, DBDailyArchive, query)
                for item in archives:
                    dailyArchive.addRecord(item)
                days[dateInt] = dailyArchive
            else:
                archive = DBFindOne(self.mongo_client, DBDailyArchive, query)
                if archive is not None:
                    days[dateInt] = archive
        return days

    def getQueryByServAndChannel(self, servName, channel):
        query = {}

        area = getServerArea(servName)
        if area is not None:
            query['area'] = area

        query['language'] = getServerLanguageByKey(servName)

        if channel != 'All':
            if self.isShuGuoAccount():
                channel = 'shuguo'

            if channel == 'shuguo' and self.isTCAccount():
                query['channel'] = 'tc'
            else:
                subChannel = self.getSubChannel(channel)
                if subChannel:
                    query['sub_channel'] = subChannel
                else:
                    query['channel'] = channel
        return query

    # The total number of account recharges, the latest recharge time
    def getAllOrderAmount(self, account, query):
        query['account_id'] = account.account_id
        orderList = DBFind(self.mongo_client, DBOrder, query, sort=[('time', -1)], noCache=True)
        amount = 0
        for order in orderList:
            amount += self.RechargeMap[order.recharge_id]
        return (amount, str(datetime.datetime.fromtimestamp(orderList[0].time))) if orderList else (amount, '')

    def colorA(self, serverList):
        def createMergeMapAndUnmergeListBy(serverList):
            mergeMap = defaultdict(list)
            unmergeList = []
            for s in serverList:
                if s != "All":
                    try:
                        servKey = servName2ServKey(s)
                        mergeServerKey = MergeServ.getMergeServKey(servKey)
                        if mergeServerKey != servKey:
                            mergeMap[mergeServerKey].append(s)
                        else:
                            unmergeList.append(s)
                    except:
                        print s, "is not normal server name"
                        unmergeList.append(s)
                else:
                    unmergeList.append(s)
            return mergeMap, unmergeList
        mergeMap, unmergeList = createMergeMapAndUnmergeListBy(serverList)
        servsList = sorted(mergeMap.values(), key=lambda x: serv_key2domains(x[0])[-1])
        serverList = [[serv, ColorClass[0]] for serv in unmergeList]
        tempColor = ColorClass[1:]
        for i, servs in enumerate(servsList):
            color = i % len(tempColor)
            for serv in servs:
                serverList.append([serv, tempColor[color]])
        return serverList

    # Report an error treatment
    def errorHandler(self, **kwargs):
        kw = AttrsDict(kwargs)

        if self.isTCAccount() and kwargs.get('channel', None) == 'shuguo':
            raise HTTPError(404, reason="no this channel")

        if self.isShuGuoAccount() and kwargs.get('channel', None) != 'shuguo':
            raise HTTPError(404, reason="no this channel")

        if 'servName' in kw and kw.servName != "All" and kw.servName not in self.servsList:
            raise HTTPError(404, 'no this server')

        if 'channel' in kw and kw.channel != "All" and kw.channel not in self.channelCache:
            raise HTTPError(404, 'no this channel')

        if "date" in kw and kw.date is None:
            raise HTTPError(404, reason="no date")

        if "startDate" in kw and "endDate" in kw:
            if None in (kw.startDate, kw.endDate):
                raise HTTPError(404, reason="no date")
            elif kw.startDate > kw.endDate:
                raise HTTPError(404, reason="date error")

    @property
    def RechargeMap(self):
        rechargeMap = {}
        from framework.csv import csv
        recharges = csv.recharges.to_dict()
        for csvID, d in recharges.iteritems():
            rechargeMap[csvID] = d.get('rmb', 0)
        return rechargeMap

    @property
    def todaydateint(self):
        return date2int(datetime.datetime.now())

    @property
    def cfg(self):
        return self.application.cfg

    @property
    def debug(self):
        return self.cfg['debug']

    @property
    def dbProcess(self):
        return self.application.dbProcess


class AuthedHandler(BaseHandler):

    def prepare(self):
        if not self.current_user:
            self.clear_cookie(SESSION_KEY)
            is_ajax = self.request.headers.get("X-Requested-With", None)
            if is_ajax:
               raise HTTPError(504, "TimeOut! Please Re-Login")
            else:
                self.redirect("/login")
