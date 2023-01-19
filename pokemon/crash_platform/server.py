#!/usr/bin/python
# -*- coding: utf-8 -*-

import signal
import datetime

import tornado.ioloop
import tornado.httpserver
import tornado.web
from tornado.log import access_log as logger

from settings import settings
from analyprocess.helper import prepare as dirPrepare
from analyprocess import Process as AnalyProcess
from object.mongo import Client as MongoDB
from object.scheme import *
from object.cache import Cache
from defines import ServerDefs
from handlers import urlMaps


class Application(tornado.web.Application):
    pass
    # def log_request(self, handler):
    #     if "log_function" in self.settings:
    #         self.settings["log_function"](handler)
    #         return

    #     if handler.get_status() < 400:
    #         log_method = logger.info
    #     elif handler.get_status() < 500:
    #         log_method = logger.warning
    #     else:
    #         log_method = logger.error
    #     request_time = 1000.0 * handler.request.request_time()
    #     log_method("%d %s %s %s %.2fms", handler.get_status(),
    #                handler._request_summary(),
    #                handler.request.headers["User-Agent"],
    #                handler.request.arguments,
    #                request_time)


class Server(object):
    def __init__(self, name):
        self.name = name
        self.cfg = ServerDefs[name]

        self.mongo = self.setupMongo()

        # ioloop
        self.ioloop = tornado.ioloop.IOLoop.instance()
        # self.ioloop.make_current()

        # 记录上传版本号
        record = Statistics.find_one(self.mongo.DBClient, {"key": "version"})
        if not record:
            Statistics.insert_one(self.mongo.DBClient, {"key": "version", "value": []})
            self.report_versions = []
        else:
            self.report_versions = record.value

        # Caches some daily statistics
        self.init()

        self.shutdown = False
        self.running = False

        application = Application(urlMaps, **settings)
        application.mongo = self.mongo
        application.report_versions = self.report_versions
        application.statCache = self.statCache
        application.tag = self.cfg['tag']
       # application.dingding = self.cfg.get('dingding')
        application.language = self.name.split('_')[-1]

        # http server
        self.http_server = tornado.httpserver.HTTPServer(application, io_loop=self.ioloop)
        self.http_server.listen(self.cfg['port'])

        # analyprocess
        self.analyProcess = None
        self.analyProcess = AnalyProcess(name)

        signal.signal(signal.SIGINT, lambda sig, frame: self.stop())
        signal.signal(signal.SIGTERM, lambda sig, frame: self.stop())

    def init(self):
        now = datetime.datetime.now()
        one = datetime.timedelta(days=1)
        s = datetime.datetime(now.year, now.month, now.day)
        query = {"report_time": {"$gte": s, "$lte": now}}

        cache_dic = {
            "today_dmp_count": DmpRecord.count(self.mongo.DBClient, query),
            "today_exc_count": ExcRecord.count(self.mongo.DBClient, query),
            "dmp_imei": set(DmpRecord.find(self.mongo.DBClient, query, distinct="imei")),
            "exc_imei": set(ExcRecord.find(self.mongo.DBClient, query, distinct="imei")),
            "dmp_server_role": set(DmpRecord.find(self.mongo.DBClient, query, distinct="server_role")),
            "exc_server_role": set(ExcRecord.find(self.mongo.DBClient, query, distinct="server_role"))
        }

        self.statCache = Cache(cache_dic, self.ioloop)

    def setupMongo(self):
        cfg = self.cfg["mongodb"]
        mongo = MongoDB(cfg["host"], cfg["port"],
            cfg["dbname"], cfg["username"], cfg["password"])

        Statistics.init(mongo.DBClient)
        Account.init(mongo.DBClient)
        SymbolFile.init(mongo.DBClient)
        DmpRecord.init(mongo.DBClient)
        DmpStatistic.init(mongo.DBClient)
        ExcRecord.init(mongo.DBClient)
        ExcStatistic.init(mongo.DBClient)
        FeedBackRecord.init(mongo.DBClient)
        BattleReport.init(mongo.DBClient)
        PlayReport.init(mongo.DBClient)
        return mongo

    def start(self):
        if self.running:
            logger.warning("%s has been running"% self.name)
            return
        self.running = True

        # 生成准备目录
        dirPrepare()

        if self.analyProcess:
            self.analyProcess.start()

        self.statCache.start()
        logger.info("%s is running"% self.name)
        self.ioloop.start()

    def stop(self):
        if self.shutdown:
            logger.warning("%s has been stopped"% self.name)
            return
        self.shutdown = True

        self.statCache.stop()

        self.http_server.stop()

        # 将版本号记录回刷数据库
        Statistics.update(self.mongo.DBClient, {"key": "version"}, {"$set": {"value": self.report_versions}})

        if self.analyProcess:
            self.analyProcess.stop()
            self.analyProcess.join()
            print "end analyProcess"

        self.ioloop.stop()
        self.mongo.close()

        logger.warning("web %s is stopped"% self.name)


if __name__ == '__main__':
    import sys
    reload(sys)
    sys.setdefaultencoding("utf-8")

    import tornado.options
    tornado.options.define("name", default="crash_platform_test", help="server name", type=str)
    tornado.options.parse_command_line()

    server = Server(tornado.options.options.name)
    server.start()
