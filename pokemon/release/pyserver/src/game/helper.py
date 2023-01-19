#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Game Helpers
'''

import framework
from framework.csv import csv, MergeServ


def getPWAwardVersion():
	version = 0
	# 合服
	cfg = MergeServ.getServCfg(framework.__server_key__)
	if cfg:
		version = cfg.pwAwardVer
	# 未合服
	for i in csv.server.version:
		cfg = csv.server.version[i]
		if cfg.pwAwardVer > 0 and cfg.server == framework.__server_key__:
			version = cfg.pwAwardVer
	return version


def getRandomTowerAwardVersion():
	version = 0
	# 合服
	cfg = MergeServ.getServCfg(framework.__server_key__)
	if cfg:
		version = cfg.randomTowerAwardVer
	# 未合服
	for i in csv.server.version:
		cfg = csv.server.version[i]
		if cfg.randomTowerAwardVer > 0 and cfg.server == framework.__server_key__:
			version = cfg.randomTowerAwardVer
	return version


def getCraftRankAwardVersion():
	version = 0
	# 合服
	cfg = MergeServ.getServCfg(framework.__server_key__)
	if cfg:
		version = cfg.craftAwardVer
	# 未合服
	for i in csv.server.version:
		cfg = csv.server.version[i]
		if cfg.craftAwardVer > 0 and cfg.server == framework.__server_key__:
			version = cfg.craftAwardVer
	return version
