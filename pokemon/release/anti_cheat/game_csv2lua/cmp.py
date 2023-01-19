#-*- coding=utf-8 -*-
# csv2lua
# 递归扫描SRC_PATH目录，读取全部csv文件，生成lua
# csv路径名去掉.csv后缀后，将分隔符替换为.，即为lua table变量名
# 如bullet\fire.csv -> bullet.fire = {...}

import os
import sys
import shutil
from collections import namedtuple

import config_csv
import config_csv_release

def deep_cmp(a, b):
	if type(a) != type(b):
		if type(a).__name__ == type(b).__name__:
			a = a._asdict()
			b = b._asdict()
		else:
			print type(a), type(b)
			raise Exception("type error")

	if isinstance(a, dict):
		if len(a) != len(b):
			print len(a), len(b)
			raise Exception("len error")

		if set(a.keys()) != set(b.keys()):
			print set(a.keys()) - set(b.keys())
			print set(b.keys()) - set(a.keys())
			raise Exception("set error")

		for k, v in a.iteritems():
			deep_cmp(a[k], b[k])

	else:
		if a != b:
			print a, b
			raise Exception("value error")

print config_csv
print type(config_csv.csv)
print config_csv.csv == config_csv_release.csv
deep_cmp(config_csv.csv, config_csv_release.csv)
