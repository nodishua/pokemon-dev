# -*- coding: utf-8 -*-
import json
import datetime
import pymongo

from tornado.web import RequestHandler
from tornado.concurrent import run_on_executor
from tornado.gen import coroutine
from concurrent.futures import ThreadPoolExecutor

from object.scheme import *
from settings import COOKIES_KEY


def datetimeSet(time_str): # time_str: 2016-06-07 09:00:00
    if isinstance(time_str, datetime.datetime):
        return time_str
    time_strL = time_str.split()
    if len(time_strL) == 1:
        return datetime.datetime.strptime(time_str, "%Y-%m-%d")
    elif len(time_strL) == 2:
        return datetime.datetime.strptime(time_str, "%Y-%m-%d %H:%M:%S")

# 解决无法json化python的date，datetime对象问题
class DatetimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime.datetime):
            return obj.strftime('%Y-%m-%d %H:%M:%S')
        elif isinstance(obj, datetime.date):
            return obj.strftime('%Y-%m-%d')
        else:
            return json.JSONEncoder.default(self, obj)


class BaseHandler(RequestHandler):
    executor = ThreadPoolExecutor(5)

    ErrStatus = {
        0: "all", # "所有状态的错误",
        -1: False, # "未处理状态的错误",
        1: True, # "已处理状态的错误",
    }

    PymongoOrder = {
        -1: pymongo.DESCENDING,
        1: pymongo.ASCENDING,
    }

    @property
    def ErrRecordType(self):
        return {
            0: "all",
            -1: DmpRecord,
            1: ExcRecord,
        }

    @property
    def ErrStatisticsType(self):
        return {
            0: "all",
            -1: DmpStatistic,
            1: ExcStatistic,
        }

    @property
    def mongo(self):
        return self.application.mongo

    @property
    def dingding(self):
        return self.application.dingding


    @property
    def Collections(self):
        return {
            "upfile_db": SymbolFile,
            "dmp_db": DmpRecord,
            "dmpst_db": DmpStatistic,
            "exre_db": ExcRecord,
            "exst_db": ExcStatistic,
        }

    @property
    def tag(self):
        return self.application.tag

    def get_current_user(self):
        return self.get_secure_cookie(COOKIES_KEY)

    def get_json_data(self, foolish=False):
        if foolish:
            return json.loads(self.request.body)

        if self.request.headers["Content-Type"] == "application/json":
            return json.loads(self.request.body)
        return None

    def get_text_data(self):
        if self.request.headers["Content-Type"] == "application/text-plain":
            return self.request.body
        return None

    def write_json(self, data):
        self.write(json.dumps(data, cls=DatetimeEncoder))

    def start2end_days(self, num=1):
        now = datetime.datetime.now()
        one = datetime.timedelta(days=1)
        s = datetime.datetime(now.year, now.month, now.day) - one * (num - 1)
        return (s, now)

    @run_on_executor
    def async_execute(self, fn, *args, **kwargs):
        result = fn(*args, **kwargs)
        return result

    def multi_async_execute(self, fns):
        return [self.async_execute(fn) for fn in fns]

    @run_on_executor
    def async_db_exec(self, fn, *args, **kwargs):
        ret = fn(self.mongo.DBClient, *args, **kwargs)
        return ret

    @property
    def versions(self):
        return self.application.report_versions

    @property
    def statCache(self):
        return self.application.statCache

    @property
    def language(self):
        return self.application.language


class AuthedHandler(BaseHandler):
    def prepare(self):
        if not self.current_user:
            self.redirect("/login")