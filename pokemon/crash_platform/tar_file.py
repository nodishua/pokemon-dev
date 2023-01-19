#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import print_function

import os
import sys
import time
import datetime
from collections import defaultdict


dmp_src = "./_dump_analysis"
dmp_target = "/mnt2/crash_platform/_dump_analysis"

debug_src = "./_app_debug"
debug_target = "/mnt2/crash_platform/_app_debug"

one_day = datetime.timedelta(days=1)
current_date = datetime.datetime.now().date()

RetainDays = 15

def _tar_dmp():
	retains = ["symbols", ]
	for i in xrange(RetainDays):
		date = current_date - i*one_day
		retains.append("%d-%02d-%02d"%(date.year, date.month, date.day))

	print("need .dmp before: %s"% retains[-1])

	for root, dirs, files in os.walk(dmp_src):
		for name in dirs:
			if name in retains:
				continue

			path_tar = os.path.join(dmp_target, name + ".tar.gz")
			cmd = "tar -czf %s %s"% (path_tar, os.path.join(dmp_src, name))
			print(cmd)
			if os.system(cmd) != 0:
				print("!!err: _tar_dmp %s fail"% name)
			else:
				if os.system("rm -r %s"% os.path.join(dmp_src, name)) != 0:
					print("!!err: rm dmp %s fail"% name)
					break

		break

	print("tar dmp over")

def _tar_debug():
	now = time.time()
	date = datetime.datetime.now()
	dur = 24*60*60 * RetainDays
	tars = []

	for root, dirs, files in os.walk(debug_src):
		for name in files:
			if not name.endswith(r".debug.log"):
				continue
			name_path = os.path.join(debug_src, name)
			stat = os.stat(name_path)
			if stat.st_mtime + dur < now:
				tars.append(name_path)
		
		print("need .debug.log count: %d"% len(tars))

		count = 0
		limit = 2000
		while tars:
			count += 1
			tar_name = str(date.year) + "-" + str(date.month) + "-" + str(date.day) + "-%d.tar.gz"% count
			print(tar_name)
			cmd = "tar -czf %s %s"% (os.path.join(debug_target, tar_name), " ".join(tars[:limit]))	
			if os.system(cmd) != 0:
				print("!!err: _tar_debug %s fail"% tar_name)
				break
			
			if os.system("rm %s"% " ".join(tars[:limit])) != 0:
				print("!!err: rm debug %s fail"% tar_name)
				break

			tars = tars[limit:]

		break

	print("tar debug over")

def tar():
	_tar_dmp()
	_tar_debug()

def show():
	print("--------------dmp:")
	result = {}
	for root, dirs, files in os.walk(dmp_src):
		for name in dirs:
			ret = os.listdir(os.path.join(dmp_src, name))
			result[name] = len(ret)
		break
	for k in sorted(result.keys()):
		print("%s : %d"% (k, result[k]))

	print("--------------debug:")
	result = defaultdict(int)
	for root, dirs, files in os.walk(debug_src):
		for name in files:
			name_path = os.path.join(debug_src, name)
			stat = os.stat(name_path)
			timeArray = time.localtime(stat.st_mtime)
			timeString = time.strftime("%Y-%m-%d", timeArray)
			result[timeString] += 1
		break
	for k in sorted(result.keys()):
		print("%s : %d"% (k, result[k]))

def main():
	funcs = {
		"help": lambda: print("help:\n用来压缩crash dmp 文件。\neg: python tar_file.py tar"),
		"tar": tar,
		"show": show
	}

	funcs[sys.argv[1]]()


if __name__ == "__main__":
	main()