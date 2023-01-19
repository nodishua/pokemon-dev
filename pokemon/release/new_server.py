#!/usr/bin/python
# -*- coding: utf-8 -*-
import subprocess
import os
import sys


HeadTemplates = """# {name}
# {ip1}(公)
# {ip2}(内)
"""
# 'open_date': datetime({year}, {month}, {day}, {hour}),

# GamePrefix = 'game.cn'
GamePrefix = 'game.cn_qd'
Language = 'cn'
NSQ = 'CNNSQDefs'
# GamePort = 10888
GamePort = 22888

GameTemplates = """	'{GamePrefix}.{servID}': <
		'ip': '{ip}',
		'port': {port},
		'nsq': {nsq},
		'open_date': datetime(2022, 3, 28, 16),
		'dependent': [
			'anticheat',
			'chat_monitor',
			'giftdb.{language}.1',
		],
	>,"""

Servers = {
	# name: (ip1, ip2)
	# 'tc-pokemon-cn-07': ("175.24.66.44", ""),
	# 'tc-pokemon-cn-08': ("49.235.219.233", ""),
	# 'tc-pokemon-cn-09': ("49.235.43.249", ""),
	# 'tc-pokemon-cn-10': ("175.24.94.71", ""),
	# 'tc-pokemon-cn-11': ("175.24.55.248", ""),
	# 'tc-pokemon-cn-12': ("212.64.32.10", ""),
	# 'tc-pokemon-cn-13': ("129.211.84.248", ""),
	# 'tc-pokemon-cn-14': ("175.24.16.53", ""),
	# "tc-pokemon-cn-15": ("49.234.76.95", ""),
	# 'tc-pokemon-cn-16': ("49.235.40.29", ""),
	# 'tc-pokemon-cn-17': ("106.54.70.57", ""),
	# 'tc-pokemon-cn-18': ("49.235.247.167", ""),
	# 'tc-pokemon-cn-19': ("49.235.16.217", ""),
	# 'tc-pokemon-cn-20': ("212.64.64.74", ""),

	'tc-pokemon-cn_qd-02': ("49.235.238.44", ""),
	'tc-pokemon-cn_qd-03': ("106.54.69.20", ""),
	'tc-pokemon-cn_qd-04': ("175.24.51.5", ""),
	'tc-pokemon-cn_qd-05': ("49.234.90.53", ""),
	'tc-pokemon-cn_qd-06': ("175.24.77.41", ""),
	'tc-pokemon-cn_qd-07': ("175.24.83.162", ""),
	'tc-pokemon-cn_qd-08': ("129.211.48.90", ""),
	'tc-pokemon-cn_qd-09': ("49.235.20.229", ""),
	'tc-pokemon-cn_qd-10': ("49.234.70.41", ""),
	'tc-pokemon-cn_qd-11': ("49.234.230.143", ""),
	'tc-pokemon-cn_qd-12': ("49.235.249.116", ""),
	
	'tc-pokemon-cn_qd-13': ("49.234.219.64", ""),
	'tc-pokemon-cn_qd-14': ("106.54.121.184", ""),
	'tc-pokemon-cn_qd-15': ("49.234.229.205", ""),
	'tc-pokemon-cn_qd-16': ("175.24.14.221", ""),
	'tc-pokemon-cn_qd-17': ("49.235.255.131", ""),

	'tc-pokemon-cn_qd-18': ("106.54.111.167", ""),
	'tc-pokemon-cn_qd-19': ("172.81.216.207", ""),
	'tc-pokemon-cn_qd-20': ("49.235.199.211", ""),
	'tc-pokemon-cn_qd-21': ("106.54.90.178", ""),
	'tc-pokemon-cn_qd-22': ("106.54.73.161", ""),

	'tc-pokemon-cn_qd-23': ("212.64.35.184", ""),
	'tc-pokemon-cn_qd-24': ("49.235.231.230", ""),
	'tc-pokemon-cn_qd-25': ("106.54.124.52", ""),
	'tc-pokemon-cn_qd-26': ("106.54.119.14", ""),
	'tc-pokemon-cn_qd-27': ("49.235.4.151", ""),

	'tc-pokemon-cn_qd-28': ("49.234.212.217", ""),
	'tc-pokemon-cn_qd-29': ("49.234.100.177", ""),
	'tc-pokemon-cn_qd-30': ("49.234.124.150", ""),
	'tc-pokemon-cn_qd-31': ("49.235.221.2", ""),
	'tc-pokemon-cn_qd-32': ("172.81.248.246", ""),

	'tc-pokemon-cn_qd-33': ("106.54.91.94", ""),
	'tc-pokemon-cn_qd-34': ("172.81.204.163", ""),
	'tc-pokemon-cn_qd-35': ("49.235.23.191", ""),
	'tc-pokemon-cn_qd-36': ("49.234.92.62", ""),
	'tc-pokemon-cn_qd-37': ("49.235.24.152", ""),

	'tc-pokemon-cn_qd-38': ("49.235.47.172", ""),
	'tc-pokemon-cn_qd-39': ("129.211.93.121", ""),
	'tc-pokemon-cn_qd-40': ("49.235.245.184", ""),
	'tc-pokemon-cn_qd-41': ("49.235.196.126", ""),
	'tc-pokemon-cn_qd-42': ("172.81.204.21", ""),

	"tc-pokemon-cn_qd-43": ("49.234.75.92", ""),
	"tc-pokemon-cn_qd-44": ("175.24.85.90", ""),
	"tc-pokemon-cn_qd-45": ("212.64.87.81", ""),
	"tc-pokemon-cn_qd-46": ("49.234.64.167", ""),
	"tc-pokemon-cn_qd-47": ("172.81.243.184", ""),
	"tc-pokemon-cn_qd-48": ("49.234.232.85", ""),
	"tc-pokemon-cn_qd-49": ("129.211.78.189", ""),
	"tc-pokemon-cn_qd-50": ("106.54.108.74", ""),
	"tc-pokemon-cn_qd-51": ("49.234.84.43", ""),
	"tc-pokemon-cn_qd-52": ("49.234.118.119", ""),
	"tc-pokemon-cn_qd-53": ("106.54.87.23", ""),
	"tc-pokemon-cn_qd-54": ("212.64.87.70", ""),
	"tc-pokemon-cn_qd-55": ("49.235.216.247", ""),
	"tc-pokemon-cn_qd-56": ("118.25.251.53", ""),

	"tc-pokemon-cn_qd-57": ("106.54.113.44", ""),
	"tc-pokemon-cn_qd-58": ("49.234.123.104", ""),
	"tc-pokemon-cn_qd-59": ("49.235.52.206", ""),
	"tc-pokemon-cn_qd-60": ("49.234.70.197", ""),
	"tc-pokemon-cn_qd-61": ("106.54.133.68", ""),
	"tc-pokemon-cn_qd-62": ("49.234.64.226", ""),
	"tc-pokemon-cn_qd-63": ("49.235.248.137", ""),
	"tc-pokemon-cn_qd-64": ("106.54.108.111", ""),
	"tc-pokemon-cn_qd-65": ("49.234.66.99", ""),
	"tc-pokemon-cn_qd-66": ("49.234.121.189", ""),
}

ServerIDMap = {
	'tc-pokemon-cn_qd-02': ['cn_qd_782'],
	'tc-pokemon-cn_qd-03': ['cn_qd_783'],
	'tc-pokemon-cn_qd-04': ['cn_qd_784'],
	'tc-pokemon-cn_qd-05': ['cn_qd_785'],
	'tc-pokemon-cn_qd-06': ['cn_qd_786'],
	'tc-pokemon-cn_qd-07': ['cn_qd_787'],
	'tc-pokemon-cn_qd-08': ['cn_qd_788'],
	'tc-pokemon-cn_qd-09': ['cn_qd_789'],
	'tc-pokemon-cn_qd-10': ['cn_qd_790'],
	'tc-pokemon-cn_qd-11': ['cn_qd_791'],
	'tc-pokemon-cn_qd-12': ['cn_qd_792'],
	'tc-pokemon-cn_qd-13': ['cn_qd_793'],
	'tc-pokemon-cn_qd-14': ['cn_qd_794'],
	'tc-pokemon-cn_qd-15': ['cn_qd_795'],
	'tc-pokemon-cn_qd-16': ['cn_qd_796'],
	'tc-pokemon-cn_qd-17': ['cn_qd_797'],
	'tc-pokemon-cn_qd-18': ['cn_qd_798'],
	'tc-pokemon-cn_qd-19': ['cn_qd_799'],
	'tc-pokemon-cn_qd-20': ['cn_qd_800'],
	'tc-pokemon-cn_qd-21': ['cn_qd_801'],
	'tc-pokemon-cn_qd-22': ['cn_qd_802'],
	'tc-pokemon-cn_qd-23': ['cn_qd_803'],
	'tc-pokemon-cn_qd-24': ['cn_qd_804'],
	'tc-pokemon-cn_qd-25': ['cn_qd_805'],
	'tc-pokemon-cn_qd-26': ['cn_qd_806'],
	'tc-pokemon-cn_qd-27': ['cn_qd_807'],
	'tc-pokemon-cn_qd-28': ['cn_qd_808'],
	'tc-pokemon-cn_qd-29': ['cn_qd_809'],
	'tc-pokemon-cn_qd-30': ['cn_qd_810'],
	'tc-pokemon-cn_qd-31': ['cn_qd_811'],
	'tc-pokemon-cn_qd-32': ['cn_qd_812'],
	'tc-pokemon-cn_qd-33': ['cn_qd_813'],
	'tc-pokemon-cn_qd-34': ['cn_qd_814'],
	'tc-pokemon-cn_qd-35': ['cn_qd_815'],
	'tc-pokemon-cn_qd-36': ['cn_qd_816'],
	'tc-pokemon-cn_qd-37': ['cn_qd_817'],
	'tc-pokemon-cn_qd-38': ['cn_qd_818'],
	'tc-pokemon-cn_qd-39': ['cn_qd_819'],
	'tc-pokemon-cn_qd-40': ['cn_qd_820'],
	'tc-pokemon-cn_qd-41': ['cn_qd_821'],
	'tc-pokemon-cn_qd-42': ['cn_qd_822'],
	'tc-pokemon-cn_qd-43': ['cn_qd_823'],
	'tc-pokemon-cn_qd-44': ['cn_qd_824'],
	'tc-pokemon-cn_qd-45': ['cn_qd_825'],
	'tc-pokemon-cn_qd-46': ['cn_qd_826'],
	'tc-pokemon-cn_qd-47': ['cn_qd_827'],
	'tc-pokemon-cn_qd-48': ['cn_qd_828'],
	'tc-pokemon-cn_qd-49': ['cn_qd_829'],
	'tc-pokemon-cn_qd-50': ['cn_qd_830'],
	'tc-pokemon-cn_qd-51': ['cn_qd_831'],
	'tc-pokemon-cn_qd-52': ['cn_qd_832'],
	'tc-pokemon-cn_qd-53': ['cn_qd_833'],
	'tc-pokemon-cn_qd-54': ['cn_qd_834'],
	'tc-pokemon-cn_qd-55': ['cn_qd_835'],
	'tc-pokemon-cn_qd-56': ['cn_qd_836'],
	'tc-pokemon-cn_qd-57': ['cn_qd_837'],
	'tc-pokemon-cn_qd-58': ['cn_qd_838'],
	'tc-pokemon-cn_qd-59': ['cn_qd_839'],
	'tc-pokemon-cn_qd-60': ['cn_qd_840'],
	'tc-pokemon-cn_qd-61': ['cn_qd_841'],
	'tc-pokemon-cn_qd-62': ['cn_qd_842'],
	'tc-pokemon-cn_qd-63': ['cn_qd_843'],
	'tc-pokemon-cn_qd-64': ['cn_qd_844'],
	'tc-pokemon-cn_qd-65': ['cn_qd_845'],
	'tc-pokemon-cn_qd-66': ['cn_qd_846'],

}

def format2json(s):
	return s.replace('<', '{').replace('>', '}')

def new():
	content = {}

	for name in sorted(Servers.keys()):
		one = []
		ip1, ip2 = Servers[name]
		for i, key in enumerate(ServerIDMap[name]):
			servID = '%d' % int(key.split('_')[-1])
			port = GamePort + 1000 * i
			s = format2json(GameTemplates.format(servID=servID, port=port, ip=ip1, GamePrefix=GamePrefix, nsq=NSQ, language=Language))
			for l in s.split("\n"):
				one.append(l+"\n")

		content[name] = one

	return content

def mod():
	content = new()
	for name in content:
		print name
		names = name.split("-")
		names[-1] = "%02d" % (int(names[-1])+1)
		cmd = 'grep -n "%s" game_defines.py'% "-".join(names)
		p = subprocess.Popen(cmd, cwd="./", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		out, err = p.communicate()
		if err:
			print err
			return

		row = int(out.split(':')[0].strip())

		lines = []
		with open('game_defines.py', 'r') as f:
			lines = f.readlines()

		content[name].reverse()
		for nl in content[name]:
			lines.insert(row-2, nl)

		with open('game_defines.py', 'w') as f:
			f.write("".join(lines))


if __name__ == "__main__":
	mod()