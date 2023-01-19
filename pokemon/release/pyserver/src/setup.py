#!/usr/bin/env python
#-*- coding:utf-8 -*-

# https://packaging.python.org/en/latest/distributing.html

from setuptools import setup, find_packages

setup(
	name = "stormfighting",
	version="1.0.7.5922",
	zip_safe = False,
	packages=find_packages(exclude=['config', 'anti-cheat', 'doc', 'sysenv', 'test', 'templates', 'csv2py']),
	
	description = "StormFighting Servers",
	long_description = "YouMi Information Technology Inc.",
	author = "HuangWei",
	author_email = "test@163.com",

	license = "YouMi",
	
	# See https://pypi.python.org/pypi?%3Aaction=list_classifiers
	classifiers=[
	
		# Pick your license as you wish (should match "license" above)
		'License :: OSI Approved :: YouMi License',
	
		# Specify the Python versions you support here. In particular, ensure
		# that you indicate whether you support Python 2, Python 3 or both.
		'Programming Language :: Python :: 2.7',
		'Programming Language :: PyPy :: 2.4',
	],
	
	keywords = "youmi stormfighting servers",
	platforms = "Independant",
	url = "um-game.com",
	install_requires=[
		"cython",
		"six",
		"lz4",
		"xdot",
		"rpdb",
		"psutil",
		"pycurl",
		"pycrypto",
		"objgraph",
		"M2Crypto",
		"msgpack-python",
		"backports.ssl-match-hostname",
	],
)
