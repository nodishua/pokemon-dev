#!/usr/bin/python
# -*- coding: utf-8 -*-
import json

pvp_defines_path = "./pvp/defines.json"
storage_defines_path = "./storage/defines.json"

with open(pvp_defines_path, 'r') as f:
	pvp_defines = json.loads(f.read())
with open(storage_defines_path, 'r') as f:
	storage_defines = json.loads(f.read())

cn_nsqlookupd = "http://172.16.2.14:4161/"
cn_mainnsqd = "172.16.2.14:4150"

dev_nsqlookupd = "http://192.168.1.125:4161/"
dev_mainnsqd = "192.168.1.125:4150"

pvp_template = """<
	"pvp.{lang}.{id}": <
        "nsqlookupd": "{nsqlookupd}",
        "mainnsqd": "{mainnsqd}",
        "services": [
            <
                "name": "arena.{lang}.{id}",
                "dependent": [
                    "storage.{lang}.{id}"
                ]
            >,
            <
                "name": "union.{lang}.{id}",
                "dependent": [
                    "storage.{lang}.{id}"
                ]
            >,
            <
                "name": "craft.{lang}.{id}",
                "dependent": [
                    "anticheat",
                    "storage.{lang}.{id}",
                    "game.{lang}.{id}"
                ]
            >,
            <
                "name": "clone.{lang}.{id}",
                "dependent": [
                    "storage.{lang}.{id}"
                ]
            >
        ]
    >
>"""
def genPvpTemplate(key):
	game_key, lang, id = key.split('.')

	if lang == 'cn' or lang == 'cn_qd':
		nsqlookupd, mainnsqd = cn_nsqlookupd, cn_mainnsqd
	elif lang == 'dev':
		nsqlookupd, mainnsqd = dev_nsqlookupd, dev_mainnsqd
	else:
		print "!!err pvp %s"% key
		return

	return pvp_template.format(lang=lang, id=id, nsqlookupd=nsqlookupd, mainnsqd=mainnsqd).replace('<', '{').replace('>', '}')

storage_template = """<
	"storage.{lang}.{id}": <
        "nsqlookupd": "{nsqlookupd}",
        "mainnsqd": "{mainnsqd}",
        "services": [
            <
                "name": "storage.{lang}.{id}",
                "mongodb": "{mongodb}",
                "dbname": "{dbname}"
            >
        ]
    >
>"""
def genStorageTemplate(key):
	game_key, lang, id = key.split('.')

	if lang == 'cn' or lang == 'cn_qd':
		nsqlookupd, mainnsqd = cn_nsqlookupd, cn_mainnsqd
		dbname = "%s_%s_%s"% (game_key, lang, id)
		# mongodb = "mongodb://gamesystem:123456@172.16.2.10:27017/%s?authMechanism=SCRAM-SHA-1&authSource=admin"% dbname
		mongodb = "mongodb://gamesystem:123456@172.16.2.28:27017/%s?authMechanism=SCRAM-SHA-1&authSource=admin"% dbname
		
	elif lang == 'dev':
		nsqlookupd, mainnsqd = dev_nsqlookupd, dev_mainnsqd
		dbname = "%s_%s%s"% (game_key, lang, id)
		mongodb = "192.168.1.96:27018"
		
	else:
		print "!!err storage %s"% key
		return

	return storage_template.format(game_key=game_key, lang=lang, id=id, nsqlookupd=nsqlookupd, mainnsqd=mainnsqd, mongodb=mongodb, dbname=dbname).replace('<', '{').replace('>', '}')

def convertKey(game_server_key, tag):
	ks = game_server_key.split('.')
	ks[0] = tag
	return '.'.join(ks)

def removeDefines(keys):
	for key in keys:
		pvp_defines.pop(convertKey(key, 'pvp'), None)
		storage_defines.pop(convertKey(key, 'storage'), None)
		print key, " pvp storage remove"

def main(keys):
	pvpLength = len(pvp_defines)
	storageLength = len(storage_defines)

	for key in keys:
		tempDict = None
		es = "tempDict="
		if convertKey(key, 'pvp') not in pvp_defines:
			es += genPvpTemplate(key)
			exec(es)
			pvp_defines.update(tempDict)
			for k in tempDict:
				print k, " success"

		tempDict = None
		es = "tempDict="
		if convertKey(key, 'storage') not in storage_defines:
			es += genStorageTemplate(key)
			exec(es)
			storage_defines.update(tempDict)
			for k in tempDict:
				print k, " success"

	# 去除一些pvp，storage的配置
	# removeDefines(['game.cn.13', 'game.cn.14', 'game.cn.15'])

	# if len(pvp_defines) >= pvpLength:
	if True:
		with open(pvp_defines_path, 'w') as f:
			json.dump(pvp_defines, f, sort_keys=True, indent=2)

	# if len(storage_defines) >= storageLength:
	if True:
		with open(storage_defines_path, 'w') as f:
			json.dump(storage_defines, f, sort_keys=True, indent=2)


if __name__ == "__main__":
	from game_defines import ServerDefs
	ServerDefs.pop('game.shenhe.1', None)
	main(ServerDefs)

