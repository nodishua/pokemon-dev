# -*- coding: utf-8 -*-
import os
import subprocess

from tornado.log import access_log as logger


def call_subprocess(command, cwd, response=True):
	if not response:
		p = subprocess.Popen(command, shell=True, cwd=cwd)
		return p
	p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd)
	out, err = p.communicate()
	if err:
		logger.error("subprocess cmd error: %s"% command)
	return out


def is_exist_file(name, path):
	for r, d, f in os.walk(path, topdown=True):
		if (name in d) or (name in f):
			return True
		return False


def write_file(file_path, file_content):
	with open(file_path, "wb") as f:
		f.write(file_content)


def read_file(file_path):
	with open(file_path, "wb") as f:
		data = f.read(file_path)
	return data