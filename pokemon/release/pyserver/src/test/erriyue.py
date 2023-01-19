#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys
sys.path.append('../')
import datetime,copy,time
from framework import todayinclock5date2int, period2date,inclock5date, nowdatetime_t, todaydate2int, nowtime_t, todayinclock5elapsedays, nowtime2int, time2int
from framework.helper import timeSubTime
from collections import namedtuple,defaultdict
import random
import gc
import weakref
import copy
DailyRecordRefreshTime = datetime.time(hour=10,minute=19)
# from framework.csv import csv
servOpen = datetime.datetime(2016, 11, 22, 10)
OpenDateTime = datetime.datetime.combine(inclock5date(servOpen) + datetime.timedelta(days=14-1), datetime.time(hour=5))
weekday = OpenDateTime.isoweekday()
if weekday >= 2: #要完整周开始
	OpenDateTime += datetime.timedelta(days=7-weekday+1)

def func(b):
	b['x'] = 3
a = {'x' : 4}
func(a)
print a