#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import lz4
import zlib
import msgpack
from Crypto.Cipher import AES

#activate pyx compiler
import pyximport
pyximport.install()

PWD = os.urandom(16)
AESIV = 'YouMi_Technology'

@profile
def test(d):
	chunk = msgpack.packb(d, use_bin_type=True)
	msgpackSize = len(chunk)
	chunk = zlib.compress(chunk)
	# print msgpackSize, len(chunk)
	pad_len = 0
	if len(chunk) % 16 != 0:
		pad_len = 16 - len(chunk) % 16
		chunk += '\0' * pad_len
	aes = AES.new(PWD, AES.MODE_CBC, AESIV)
	chunk = chr(pad_len) + aes.encrypt(chunk)
	return chunk

@profile
def testlz4(d):
	chunk = msgpack.packb(d, use_bin_type=True)
	msgpackSize = len(chunk)
	chunk = lz4.dumps(chunk)
	# print msgpackSize, len(chunk)
	pad_len = 0
	if len(chunk) % 16 != 0:
		pad_len = 16 - len(chunk) % 16
		chunk += '\0' * pad_len
	aes = AES.new(PWD, AES.MODE_CBC, AESIV)
	chunk = chr(pad_len) + aes.encrypt(chunk)
	return chunk

# @profile
def testCy(d):
	chunk = msgpack.packb(d, use_bin_type=True)
	msgpackSize = len(chunk)
	chunk = zlib.compress(chunk)
	pad_len = 0
	if len(chunk) % 16 != 0:
		pad_len = 16 - len(chunk) % 16
		chunk += '\0' * pad_len
	aes = AES.new(PWD, AES.MODE_CBC, AESIV)
	chunk = chr(pad_len) + aes.encrypt(chunk)
	return chunk

if __name__ == '__main__':
	import time
	import timeit
	
	from test_data import csv
	from model_data import model

	chunk = msgpack.packb(csv, use_bin_type=True)
	msgpackSize = len(chunk)
	print (msgpackSize, len(zlib.compress(chunk)), len(lz4.dumps(chunk)))

	chunk = msgpack.packb(model, use_bin_type=True)
	msgpackSize = len(chunk)
	print (msgpackSize, len(zlib.compress(chunk)), len(lz4.dumps(chunk)))

	# test(csv)
	# testlz4(csv)

	# kernprof -l test.py 
	# python -m line_profiler test.py.lprof
	N = 10000

	st = time.time()
	for i in xrange(N):
		test(csv)
		test(model)
	et = time.time()
	print (et - st, N/(et - st))

	st = time.time()
	for i in xrange(N):
		testlz4(csv)
		testlz4(model)
	et = time.time()
	print (et - st, N/(et - st))



# Timer unit: 1e-06 s

# Total time: 14.3 s
# File: test.py
# Function: test at line 17

# Line #      Hits         Time  Per Hit   % Time  Line Contents
# ==============================================================
#     17                                           @profile
#     18                                           def test(d):
#     19     20000      4834688    241.7     33.8         chunk = msgpack.packb(d, use_bin_type=True)
#     20     20000        15677      0.8      0.1         msgpackSize = len(chunk)
#     21     20000      8622646    431.1     60.3         chunk = zlib.compress(chunk)
#     22                                                  # print msgpackSize, len(chunk)
#     23     20000        12687      0.6      0.1         pad_len = 0
#     24     20000        13079      0.7      0.1         if len(chunk) % 16 != 0:
#     25     20000        11239      0.6      0.1                 pad_len = 16 - len(chunk) % 16
#     26     20000        17781      0.9      0.1                 chunk += '\0' * pad_len
#     27     20000       148851      7.4      1.0         aes = AES.new(PWD, AES.MODE_CBC, AESIV)
#     28     20000       614679     30.7      4.3         chunk = chr(pad_len) + aes.encrypt(chunk)
#     29     20000         8711      0.4      0.1         return chunk

# Total time: 6.38886 s
# File: test.py
# Function: testlz4 at line 31

# Line #      Hits         Time  Per Hit   % Time  Line Contents
# ==============================================================
#     31                                           @profile
#     32                                           def testlz4(d):
#     33     20000      4780198    239.0     74.8         chunk = msgpack.packb(d, use_bin_type=True)
#     34     20000        14313      0.7      0.2         msgpackSize = len(chunk)
#     35     20000       629184     31.5      9.8         chunk = lz4.dumps(chunk)
#     36                                                  # print msgpackSize, len(chunk)
#     37     20000         8463      0.4      0.1         pad_len = 0
#     38     20000        10530      0.5      0.2         if len(chunk) % 16 != 0:
#     39     20000         9768      0.5      0.2                 pad_len = 16 - len(chunk) % 16
#     40     20000        12532      0.6      0.2                 chunk += '\0' * pad_len
#     41     20000       115600      5.8      1.8         aes = AES.new(PWD, AES.MODE_CBC, AESIV)
#     42     20000       799882     40.0     12.5         chunk = chr(pad_len) + aes.encrypt(chunk)
#     43     20000         8391      0.4      0.1         return chunk