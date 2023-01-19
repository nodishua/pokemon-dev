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

	# decode
	data = chunk
	pad_len = ord(data[0])
	aes = AES.new(PWD, AES.MODE_CBC, AESIV)
	data = aes.decrypt(data[1:])
	if pad_len > 0:
		data = data[:-pad_len]
	data = zlib.decompress(data)
	data = msgpack.unpackb(data, encoding='utf-8')

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

	# decode
	data = chunk
	pad_len = ord(data[0])
	aes = AES.new(PWD, AES.MODE_CBC, AESIV)
	data = aes.decrypt(data[1:])
	if pad_len > 0:
		data = data[:-pad_len]
	data = lz4.uncompress(data)
	data = msgpack.unpackb(data, encoding='utf-8')

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

	small_model = {
		'gate_chanllenge' : 456,
		'buy_herogate_times': 'xxxsdasd',
		'pvp_pw_times' : 956,
		'equip_advance' : 4952,
		'draw_card' : 985,
		'gate_times' : True,
		'pvp_shop_refresh_times' : 87536,
		'boss_gate' : 1025.5,
		'pvp_pw_last_time' : 954,
		'id' : {1: 'xxx', 'cc': 23, 2041:515},
		'equip_zhulian' : 456279,
		'buy_pw_times' : 'hasudsd',
		'skill_up' : 1,
		'buy_pw_cd_times' : 15,
		'hero_gate_chanllenge' : 55,
		'yz_shop_refresh_times' : 'huangwei',
		'huodong_chanllenge' : 789,
		'yz_refresh_time' : '1234562',
		'date' : 2014,
		'lianjin_times' : 201548,
		'buy_stamina_times' : 654,
		'role_db_id' : ['a','bb','ccc','ddef'],
	}

	chunk = msgpack.packb(csv, use_bin_type=True)
	msgpackSize = len(chunk)
	print msgpackSize, len(zlib.compress(chunk)), len(lz4.dumps(chunk))

	chunk = msgpack.packb(model, use_bin_type=True)
	msgpackSize = len(chunk)
	print msgpackSize, len(zlib.compress(chunk)), len(lz4.dumps(chunk))

	chunk = msgpack.packb(small_model, use_bin_type=True)
	msgpackSize = len(chunk)
	print msgpackSize, len(zlib.compress(chunk)), len(lz4.dumps(chunk))

	# test(csv)
	# testlz4(csv)


	# kernprof -l pack_benchmark.py 
	# python -m line_profiler pack_benchmark.py.lprof
	# python -m memory_profiler pack_benchmark.py
	N = 10000

	st = time.time()
	for i in xrange(N):
		# test(csv)
		# test(model)
		test(small_model)
	et = time.time()
	print et - st, N/(et - st)

	st = time.time()
	for i in xrange(N):
		# testlz4(csv)
		# testlz4(model)
		testlz4(small_model)
	et = time.time()
	print et - st, N/(et - st)



# Timer unit: 1e-06 s

# Total time: 1.10042 s
# File: pack_benchmark.py
# Function: test at line 17

# Line #      Hits         Time  Per Hit   % Time  Line Contents
# ==============================================================
#     17                                           @profile
#     18                                           def test(d):
#     19     10000       106318     10.6      9.7         chunk = msgpack.packb(d, use_bin_type=True)
#     20     10000        12945      1.3      1.2         msgpackSize = len(chunk)
#     21     10000       316302     31.6     28.7         chunk = zlib.compress(chunk)
#     22                                                  # print msgpackSize, len(chunk)
#     23     10000        11226      1.1      1.0         pad_len = 0
#     24     10000        13894      1.4      1.3         if len(chunk) % 16 != 0:
#     25     10000        11942      1.2      1.1                 pad_len = 16 - len(chunk) % 16
#     26     10000        17987      1.8      1.6                 chunk += '\0' * pad_len
#     27     10000       119947     12.0     10.9         aes = AES.new(PWD, AES.MODE_CBC, AESIV)
#     28     10000        81461      8.1      7.4         chunk = chr(pad_len) + aes.encrypt(chunk)
#     29                                           
#     30                                                  # decode
#     31     10000        11012      1.1      1.0         data = chunk
#     32     10000        12965      1.3      1.2         pad_len = ord(data[0])
#     33     10000       103221     10.3      9.4         aes = AES.new(PWD, AES.MODE_CBC, AESIV)
#     34     10000        72417      7.2      6.6         data = aes.decrypt(data[1:])
#     35     10000        11169      1.1      1.0         if pad_len > 0:
#     36     10000        15141      1.5      1.4                 data = data[:-pad_len]
#     37     10000        98977      9.9      9.0         data = zlib.decompress(data)
#     38     10000        83500      8.3      7.6         data = msgpack.unpackb(data, encoding='utf-8')

# Total time: 0.699615 s
# File: pack_benchmark.py
# Function: testlz4 at line 40

# Line #      Hits         Time  Per Hit   % Time  Line Contents
# ==============================================================
#     40                                           @profile
#     41                                           def testlz4(d):
#     42     10000        94477      9.4     13.5         chunk = msgpack.packb(d, use_bin_type=True)
#     43     10000        12574      1.3      1.8         msgpackSize = len(chunk)
#     44     10000        36063      3.6      5.2         chunk = lz4.dumps(chunk)
#     45                                                  # print msgpackSize, len(chunk)
#     46     10000         9898      1.0      1.4         pad_len = 0
#     47     10000        12670      1.3      1.8         if len(chunk) % 16 != 0:
#     48     10000        11576      1.2      1.7                 pad_len = 16 - len(chunk) % 16
#     49     10000        15398      1.5      2.2                 chunk += '\0' * pad_len
#     50     10000       108402     10.8     15.5         aes = AES.new(PWD, AES.MODE_CBC, AESIV)
#     51     10000        82014      8.2     11.7         chunk = chr(pad_len) + aes.encrypt(chunk)
#     52                                           
#     53                                                  # decode
#     54     10000        10458      1.0      1.5         data = chunk
#     55     10000        12675      1.3      1.8         pad_len = ord(data[0])
#     56     10000       100894     10.1     14.4         aes = AES.new(PWD, AES.MODE_CBC, AESIV)
#     57     10000        76567      7.7     10.9         data = aes.decrypt(data[1:])
#     58     10000        10872      1.1      1.6         if pad_len > 0:
#     59     10000        13605      1.4      1.9                 data = data[:-pad_len]
#     60     10000        18961      1.9      2.7         data = lz4.uncompress(data)
#     61     10000        72511      7.3     10.4         data = msgpack.unpackb(data, encoding='utf-8')