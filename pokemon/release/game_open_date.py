#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import json
import datetime
from game_defines import ServerDefs

names = {}

merged = {}
for key, cfg in ServerDefs.iteritems():
	for k in cfg.get('alias', []):
		merged[k] = key

now = datetime.datetime.now()
def server_open_date(language):
	for i in xrange(1, 9999):
		key = 'game.%s.%d' % (language, i)
		if key not in ServerDefs and key not in merged:
			break

		conf = ServerDefs[merged.get(key, key)]
		name = names.get(key)
		if False and now < conf['open_date']:
			break
		if key in merged:
			print key, '-->', merged[key], conf['open_date'], 'weekday', conf['open_date'].isoweekday(), name, conf['ip']
		else:
			print key, conf['open_date'], 'weekday', conf['open_date'].isoweekday(), name, conf['ip']

def main():
	global names
	language = sys.argv[1]
	name = 'login/conf/%s/names.json' % language.split('_')[0]
	if language == 'xy':
		name = 'login/conf/cn/names.json'
	with open(name, 'r') as fp:
		d = json.load(fp)
		names = {v['key'].encode('utf-8'): v['name'].encode('utf-8') for v in d}

	server_open_date(language)

if __name__ == '__main__':
	main()
