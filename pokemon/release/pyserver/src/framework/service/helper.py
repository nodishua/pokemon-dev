#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

# service key/name 命名规范
# service.[language.]id
# game.tw.1
from framework.csv import MergeServ


def service_key2id(key):
	domains = key.split('.')
	return int(domains[-1])

def service_key2domains(key):
	domains = key.split('.')
	if len(domains) == 3:
		return domains
	return [domains[0], None, domains[1]]

def service_key(service, id, language=None):
	domains = filter(lambda t: t is not None, [service, language, str(id)])
	return '.'.join(domains)

def service_domains2key(domains):
	domains = filter(lambda t: t is not None, domains)
	return '.'.join(domains)

def game2pvp(key):
	domains = service_key2domains(key)
	domains[0] = 'pvp'
	return service_domains2key(domains)

def gamemerge2game(key):
	domains = service_key2domains(key)
	domains[0] = 'game'
	return service_domains2key(domains)
