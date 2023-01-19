#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2019 TianJi Information Technology Inc.
'''

import os
import sys
import time
import random
import pprint

from fabric import *
from env import config

from functools import wraps
from group import MyThreadingGroup

roledefs = {
	'localhost': ['heat02', 'heat03'],
	'machines': ['tc-pokemon-cn-mq', 'tc-pokemon-cn-login', 'tc-pokemon-cn-01'],

	'cngame': [
		'tc-pokemon-cn-01',
		'tc-pokemon-cn-02',
		'tc-pokemon-cn-03',
		'tc-pokemon-cn-04',
		'tc-pokemon-cn-05',
		'tc-pokemon-cn-06',
		'tc-pokemon-cn-07',
		'tc-pokemon-cn-08',
		'tc-pokemon-cn-09',
		'tc-pokemon-cn-10',
		'tc-pokemon-cn-11',
		'tc-pokemon-cn-12',
		'tc-pokemon-cn-13',
		'tc-pokemon-cn-14',
		'tc-pokemon-cn-15',
		'tc-pokemon-cn-16',
		'tc-pokemon-cn-17',
		'tc-pokemon-cn-18',
		'tc-pokemon-cn-19',
		'tc-pokemon-cn-20',
		'tc-pokemon-cn-21',
		'tc-pokemon-cn-22',
		'tc-pokemon-cn-23',
		'tc-pokemon-cn-24',
		'tc-pokemon-cn-25',
		'tc-pokemon-cn-26',
		'tc-pokemon-cn-27',
		'tc-pokemon-cn-28',
		'tc-pokemon-cn-29',
		'tc-pokemon-cn-30',
		'tc-pokemon-cn-31',
		'tc-pokemon-cn-32',
		'tc-pokemon-cn-33',
		'tc-pokemon-cn-34',
		'tc-pokemon-cn-35',
		'tc-pokemon-cn-36',
		'tc-pokemon-cn-37',
		'tc-pokemon-cn-38',
		'tc-pokemon-cn-39',
		'tc-pokemon-cn-40',
		'tc-pokemon-cn-41',
		'tc-pokemon-cn-42',
		'tc-pokemon-cn-43',
		'tc-pokemon-cn-44',
	],

	'qdgame': [
		'tc-pokemon-cn_qd-01',
		'tc-pokemon-cn_qd-02',
		'tc-pokemon-cn_qd-03',
		'tc-pokemon-cn_qd-04',
		'tc-pokemon-cn_qd-05',
		'tc-pokemon-cn_qd-06',
		'tc-pokemon-cn_qd-07',
		'tc-pokemon-cn_qd-08',
		'tc-pokemon-cn_qd-09',
		'tc-pokemon-cn_qd-10',
		'tc-pokemon-cn_qd-11',
		'tc-pokemon-cn_qd-12',
		'tc-pokemon-cn_qd-13',
		'tc-pokemon-cn_qd-14',
		'tc-pokemon-cn_qd-15',
		'tc-pokemon-cn_qd-16',
		'tc-pokemon-cn_qd-17',
		'tc-pokemon-cn_qd-18',
		'tc-pokemon-cn_qd-19',
		'tc-pokemon-cn_qd-20',
		'tc-pokemon-cn_qd-21',
		'tc-pokemon-cn_qd-22',
		'tc-pokemon-cn_qd-23',
		'tc-pokemon-cn_qd-24',
		'tc-pokemon-cn_qd-25',
		'tc-pokemon-cn_qd-26',
		'tc-pokemon-cn_qd-27',
		'tc-pokemon-cn_qd-28',
		'tc-pokemon-cn_qd-29',
		'tc-pokemon-cn_qd-30',
		'tc-pokemon-cn_qd-31',
		'tc-pokemon-cn_qd-32',
		'tc-pokemon-cn_qd-33',
		'tc-pokemon-cn_qd-34',
		'tc-pokemon-cn_qd-35',
		'tc-pokemon-cn_qd-36',
		'tc-pokemon-cn_qd-37',
		'tc-pokemon-cn_qd-38',
		'tc-pokemon-cn_qd-39',
		'tc-pokemon-cn_qd-40',
		'tc-pokemon-cn_qd-41',
		'tc-pokemon-cn_qd-42',
		'tc-pokemon-cn_qd-43',
		'tc-pokemon-cn_qd-44',
		'tc-pokemon-cn_qd-45',
		'tc-pokemon-cn_qd-46',
		'tc-pokemon-cn_qd-47',
		'tc-pokemon-cn_qd-48',
		'tc-pokemon-cn_qd-49',
		'tc-pokemon-cn_qd-50',
		'tc-pokemon-cn_qd-51',
		'tc-pokemon-cn_qd-52',
		'tc-pokemon-cn_qd-53',
		'tc-pokemon-cn_qd-54',
		'tc-pokemon-cn_qd-55',
		'tc-pokemon-cn_qd-56',
		'tc-pokemon-cn_qd-57',
		'tc-pokemon-cn_qd-58',
		'tc-pokemon-cn_qd-59',
		'tc-pokemon-cn_qd-60',
		'tc-pokemon-cn_qd-61',
		'tc-pokemon-cn_qd-62',
		'tc-pokemon-cn_qd-63',
		'tc-pokemon-cn_qd-64',
		'tc-pokemon-cn_qd-65',
		'tc-pokemon-cn_qd-66',
		'tc-pokemon-cn_qd-67',
		'tc-pokemon-cn_qd-68',
		'tc-pokemon-cn_qd-69',
		'tc-pokemon-cn_qd-70',
		'tc-pokemon-cn_qd-71',
		'tc-pokemon-cn_qd-72',
		'tc-pokemon-cn_qd-73',
		'tc-pokemon-cn_qd-74',
		'tc-pokemon-cn_qd-75',
		'tc-pokemon-cn_qd-76',
		'tc-pokemon-cn_qd-77',
		'tc-pokemon-cn_qd-78',
		'tc-pokemon-cn_qd-79',
		'tc-pokemon-cn_qd-80',
		'tc-pokemon-cn_qd-81',
		'tc-pokemon-cn_qd-82',
		'tc-pokemon-cn_qd-83',
		'tc-pokemon-cn_qd-84',
		'tc-pokemon-cn_qd-85',
		'tc-pokemon-cn_qd-86',
		'tc-pokemon-cn_qd-87',
		'tc-pokemon-cn_qd-88',
		'tc-pokemon-cn_qd-89',
		'tc-pokemon-cn_qd-90',
		'tc-pokemon-cn_qd-91',
		'tc-pokemon-cn_qd-92',
		'tc-pokemon-cn_qd-93',
		'tc-pokemon-cn_qd-94',
		'tc-pokemon-cn_qd-95',
		'tc-pokemon-cn_qd-96',
		'tc-pokemon-cn_qd-97',
		'tc-pokemon-cn_qd-98',
		'tc-pokemon-cn_qd-99',
		'tc-pokemon-cn_qd-100',
		'tc-pokemon-cn_qd-101',
		'tc-pokemon-cn_qd-102',
		'tc-pokemon-cn_qd-103',
		'tc-pokemon-cn_qd-104',
		'tc-pokemon-cn_qd-105',
		'tc-pokemon-cn_qd-106',
		'tc-pokemon-cn_qd-107',
		'tc-pokemon-cn_qd-108',
		'tc-pokemon-cn_qd-109',
		'tc-pokemon-cn_qd-110',
		'tc-pokemon-cn_qd-111',
		'tc-pokemon-cn_qd-112',
		'tc-pokemon-cn_qd-113',
		'tc-pokemon-cn_qd-114',
		'tc-pokemon-cn_qd-115',
		'tc-pokemon-cn_qd-116',
		'tc-pokemon-cn_qd-117',
		'tc-pokemon-cn_qd-118',
		'tc-pokemon-cn_qd-119',
		'tc-pokemon-cn_qd-120',
		'tc-pokemon-cn_qd-121',
		'tc-pokemon-cn_qd-122',
		'tc-pokemon-cn_qd-123',
		'tc-pokemon-cn_qd-124',
		'tc-pokemon-cn_qd-125',
		'tc-pokemon-cn_qd-126',
		'tc-pokemon-cn_qd-127',
	],

	'xygame': [
		'xy-pokemon-cn-01',
		'xy-pokemon-cn-02',
		'xy-pokemon-cn-03',
		'xy-pokemon-cn-04',
		'xy-pokemon-cn-05',
		'xy-pokemon-cn-06',
		'xy-pokemon-cn-07',
		'xy-pokemon-cn-08',
		'xy-pokemon-cn-09',
		'xy-pokemon-cn-10',
	],

	'twgame': [
		'ks-pokemon-tw-01',
		'ks-pokemon-tw-02',
		'ks-pokemon-tw-03',
		'ks-pokemon-tw-04',
		'ks-pokemon-tw-05',
		'ks-pokemon-tw-06',
		'ks-pokemon-tw-07',
		'ks-pokemon-tw-08',
		'ks-pokemon-tw-09',
		'ks-pokemon-tw-10',
		'ks-pokemon-tw-11',
		'ks-pokemon-tw-12',
	],

	'krgame': [
		'tc-pokemon-kr-01',
		'tc-pokemon-kr-02',
		'tc-pokemon-kr-03',
		'tc-pokemon-kr-04',
		'tc-pokemon-kr-05',
		'tc-pokemon-kr-06',
		'tc-pokemon-kr-07',
		'tc-pokemon-kr-08',
		'tc-pokemon-kr-09',
		'tc-pokemon-kr-10',
		# 'tc-pokemon-kr-11',
		# 'tc-pokemon-kr-12',
		# 'tc-pokemon-kr-13',
		# 'tc-pokemon-kr-14',
		# 'tc-pokemon-kr-15',
		# 'tc-pokemon-kr-16',
	],

	'engame': [
		'tc-pokemon-en-01',
		'tc-pokemon-en-02',
		'tc-pokemon-en-03',
		'tc-pokemon-en-04',
		'tc-pokemon-en-05',
		'tc-pokemon-en-06',
		'tc-pokemon-en-07',
		'tc-pokemon-en-08',
		'tc-pokemon-en-09',
		'tc-pokemon-en-10',
		'tc-pokemon-en-11',
		'tc-pokemon-en-12',
		'tc-pokemon-en-13',
		'tc-pokemon-en-14',
		'tc-pokemon-en-15',
		'tc-pokemon-en-16',
		'tc-pokemon-en-17',
		'tc-pokemon-en-18',
		'tc-pokemon-en-19',
	],

	'alllogin': [
		'tc-pokemon-cn-login',
		'xy-pokemon-cn-login',
		'tc-pokemon-kr-login',
		'tc-pokemon-en-login',
		'ks-pokemon-tw-login',
	],

	'allcomment': [
		'tc-pokemon-cn_qd-88',
		'tc-pokemon-kr-05',
		'tc-pokemon-en-01',
		'ks-pokemon-tw-01',
		'xy-pokemon-cn-01',
	],

	'allmq': [
		'tc-pokemon-cn-mq',
		'tc-pokemon-cn-mq-02',

		'tc-pokemon-kr-mq',
		'tc-pokemon-en-mq',
		'ks-pokemon-tw-mq',
	],

	'allgm': [
		'tc-pokemon-cn-gm',
		'ks-pokemon-tw-gm',
	],

	'other': [
		'ks-pokemon-tw-01',
		'ks-pokemon-tw-02',
	],
}

roledefs['allgame'] = []
roledefs['allgame'] += roledefs['cngame']
roledefs['allgame'] += roledefs['qdgame']
roledefs['allgame'] += roledefs['xygame']
#roledefs['allgame'] += roledefs['krgame']
#roledefs['allgame'] += roledefs['twgame']
#roledefs['allgame'] += roledefs['engame']

roledefs['all'] = roledefs['alllogin'] + roledefs['allmq'] + roledefs['allgame'] + roledefs['allgm']

ServerNameList = ['game_server', 'pvp_server', 'storage_server']
# ServerNameList = ['pvp_server', 'storage_server']
# ServerNameList = ['pvp_server']
# ServerNameList = ['game_server']

ServerIDMap = {
	'localhost': [],

	'tc-pokemon-cn-01': ['cn_01', 'cn_02', 'cn_03'],
	'tc-pokemon-cn-02': ['cn_05', 'cn_06'],
	'tc-pokemon-cn-03': ['cn_07', 'cn_08'],
	'tc-pokemon-cn-04': ['cn_09', 'cn_10'],
	'tc-pokemon-cn-05': ['cn_11', 'cn_12'],
	'tc-pokemon-cn-06': ['cn_13', 'cn_04'],
	'tc-pokemon-cn-07': ['cn_14', 'cn_15', 'cn_16', 'cn_17', 'cn_46', 'cn_54', 'cn_62', 'cn_77', 'cn_86', 'cn_95', 'cn_154', 'cn_168', 'cn_182', 'cn_196', 'cn_210', 'cn_224', 'cn_430', 'cn_456'],
	'tc-pokemon-cn-08': ['cn_18', 'cn_19', 'cn_20', 'cn_21', 'cn_47', 'cn_55', 'cn_63', 'cn_78', 'cn_87', 'cn_96', 'cn_155', 'cn_169', 'cn_183', 'cn_197', 'cn_211', 'cn_225', 'cn_431', 'cn_457'],
	'tc-pokemon-cn-09': ['cn_22', 'cn_23', 'cn_24', 'cn_25', 'cn_48', 'cn_56', 'cn_64', 'cn_79', 'cn_88', 'cn_97', 'cn_156', 'cn_170', 'cn_184', 'cn_198', 'cn_212', 'cn_226', 'cn_432', 'cn_458'],
	'tc-pokemon-cn-10': ['cn_26', 'cn_27', 'cn_28', 'cn_29', 'cn_49', 'cn_57', 'cn_65', 'cn_80', 'cn_89', 'cn_98', 'cn_157', 'cn_171', 'cn_185', 'cn_199', 'cn_213', 'cn_227', 'cn_433', 'cn_459'],
	'tc-pokemon-cn-11': ['cn_30', 'cn_31', 'cn_32', 'cn_33', 'cn_50', 'cn_58', 'cn_66', 'cn_81', 'cn_90', 'cn_99', 'cn_158', 'cn_172', 'cn_186', 'cn_200', 'cn_214', 'cn_228', 'cn_434', 'cn_460'],
	'tc-pokemon-cn-12': ['cn_34', 'cn_35', 'cn_36', 'cn_37', 'cn_51', 'cn_59', 'cn_67', 'cn_82', 'cn_91', 'cn_100', 'cn_159', 'cn_173', 'cn_187', 'cn_201', 'cn_215', 'cn_229', 'cn_435', 'cn_461'],
	'tc-pokemon-cn-13': ['cn_38', 'cn_39', 'cn_40', 'cn_41', 'cn_52', 'cn_60', 'cn_68', 'cn_83', 'cn_92', 'cn_101', 'cn_160', 'cn_174', 'cn_188', 'cn_202', 'cn_216', 'cn_230', 'cn_436', 'cn_462'],
	'tc-pokemon-cn-14': ['cn_42', 'cn_43', 'cn_44', 'cn_45', 'cn_53', 'cn_61', 'cn_69', 'cn_84', 'cn_93', 'cn_102', 'cn_161', 'cn_175', 'cn_189', 'cn_203', 'cn_217', 'cn_231', 'cn_437', 'cn_463'],
	'tc-pokemon-cn-15': ['cn_70', 'cn_71', 'cn_72', 'cn_73', 'cn_74', 'cn_75', 'cn_76', 'cn_85', 'cn_94', 'cn_103', 'cn_162', 'cn_176', 'cn_190', 'cn_204', 'cn_218', 'cn_232', 'cn_438', 'cn_464'],
	'tc-pokemon-cn-16': ['cn_104', 'cn_109', 'cn_114', 'cn_119', 'cn_124', 'cn_129', 'cn_134', 'cn_139', 'cn_144', 'cn_149', 'cn_163', 'cn_177', 'cn_191', 'cn_205', 'cn_219', 'cn_233', 'cn_439', 'cn_465'],
	'tc-pokemon-cn-17': ['cn_105', 'cn_110', 'cn_115', 'cn_120', 'cn_125', 'cn_130', 'cn_135', 'cn_140', 'cn_145', 'cn_150', 'cn_164', 'cn_178', 'cn_192', 'cn_206', 'cn_220', 'cn_234', 'cn_440', 'cn_466'],
	'tc-pokemon-cn-18': ['cn_106', 'cn_111', 'cn_116', 'cn_121', 'cn_126', 'cn_131', 'cn_136', 'cn_141', 'cn_146', 'cn_151', 'cn_165', 'cn_179', 'cn_193', 'cn_207', 'cn_221', 'cn_235', 'cn_441', 'cn_467'],
	'tc-pokemon-cn-19': ['cn_107', 'cn_112', 'cn_117', 'cn_122', 'cn_127', 'cn_132', 'cn_137', 'cn_142', 'cn_147', 'cn_152', 'cn_166', 'cn_180', 'cn_194', 'cn_208', 'cn_222', 'cn_236', 'cn_442', 'cn_468'],
	'tc-pokemon-cn-20': ['cn_108', 'cn_113', 'cn_118', 'cn_123', 'cn_128', 'cn_133', 'cn_138', 'cn_143', 'cn_148', 'cn_153', 'cn_167', 'cn_181', 'cn_195', 'cn_209', 'cn_223', 'cn_237', 'cn_443', 'cn_469'],
	'tc-pokemon-cn-21': ['cn_238', 'cn_239', 'cn_240', 'cn_241', 'cn_250', 'cn_251', 'cn_252', 'cn_253', 'cn_262', 'cn_263', 'cn_264', 'cn_265', 'cn_274', 'cn_277', 'cn_280', 'cn_283', 'cn_444', 'cn_470'],
	'tc-pokemon-cn-22': ['cn_242', 'cn_243', 'cn_244', 'cn_245', 'cn_254', 'cn_255', 'cn_256', 'cn_257', 'cn_266', 'cn_267', 'cn_268', 'cn_269', 'cn_275', 'cn_278', 'cn_281', 'cn_284', 'cn_445', 'cn_471'],
	'tc-pokemon-cn-23': ['cn_246', 'cn_247', 'cn_248', 'cn_249', 'cn_258', 'cn_259', 'cn_260', 'cn_261', 'cn_270', 'cn_271', 'cn_272', 'cn_273', 'cn_276', 'cn_279', 'cn_282', 'cn_285', 'cn_446', 'cn_472'],
	'tc-pokemon-cn-24': ['cn_286', 'cn_289', 'cn_292', 'cn_295', 'cn_298', 'cn_301', 'cn_304', 'cn_307', 'cn_310', 'cn_313', 'cn_376', 'cn_385', 'cn_394', 'cn_403', 'cn_412', 'cn_421', 'cn_537', 'cn_553'],
	'tc-pokemon-cn-25': ['cn_287', 'cn_290', 'cn_293', 'cn_296', 'cn_299', 'cn_302', 'cn_305', 'cn_308', 'cn_311', 'cn_314', 'cn_377', 'cn_386', 'cn_395', 'cn_404', 'cn_413', 'cn_422', 'cn_538', 'cn_554'],
	'tc-pokemon-cn-26': ['cn_288', 'cn_291', 'cn_294', 'cn_297', 'cn_300', 'cn_303', 'cn_306', 'cn_309', 'cn_312', 'cn_315', 'cn_378', 'cn_387', 'cn_396', 'cn_405', 'cn_414', 'cn_423', 'cn_539', 'cn_555'],
	'tc-pokemon-cn-27': ['cn_316', 'cn_322', 'cn_328', 'cn_334', 'cn_340', 'cn_346', 'cn_352', 'cn_358', 'cn_364', 'cn_370', 'cn_379', 'cn_388', 'cn_397', 'cn_406', 'cn_415', 'cn_424', 'cn_540', 'cn_556'],
	'tc-pokemon-cn-28': ['cn_317', 'cn_323', 'cn_329', 'cn_335', 'cn_341', 'cn_347', 'cn_353', 'cn_359', 'cn_365', 'cn_371', 'cn_380', 'cn_389', 'cn_398', 'cn_407', 'cn_416', 'cn_425', 'cn_541', 'cn_557'],
	'tc-pokemon-cn-29': ['cn_318', 'cn_324', 'cn_330', 'cn_336', 'cn_342', 'cn_348', 'cn_354', 'cn_360', 'cn_366', 'cn_372', 'cn_381', 'cn_390', 'cn_399', 'cn_408', 'cn_417', 'cn_426', 'cn_542', 'cn_558'],
	'tc-pokemon-cn-30': ['cn_319', 'cn_325', 'cn_331', 'cn_337', 'cn_343', 'cn_349', 'cn_355', 'cn_361', 'cn_367', 'cn_373', 'cn_382', 'cn_391', 'cn_400', 'cn_409', 'cn_418', 'cn_427', 'cn_543', 'cn_559'],
	'tc-pokemon-cn-31': ['cn_320', 'cn_326', 'cn_332', 'cn_338', 'cn_344', 'cn_350', 'cn_356', 'cn_362', 'cn_368', 'cn_374', 'cn_383', 'cn_392', 'cn_401', 'cn_410', 'cn_419', 'cn_428', 'cn_544', 'cn_560'],
	'tc-pokemon-cn-32': ['cn_321', 'cn_327', 'cn_333', 'cn_339', 'cn_345', 'cn_351', 'cn_357', 'cn_363', 'cn_369', 'cn_375', 'cn_384', 'cn_393', 'cn_402', 'cn_411', 'cn_420', 'cn_429', 'cn_545', 'cn_561'],
	'tc-pokemon-cn-33': ['cn_447', 'cn_448', 'cn_449', 'cn_450', 'cn_473', 'cn_474', 'cn_475', 'cn_476', 'cn_477', 'cn_527', 'cn_534', 'cn_546', 'cn_562', 'cn_569', 'cn_576', 'cn_577', 'cn_584', 'cn_591'],
	'tc-pokemon-cn-34': ['cn_451', 'cn_452', 'cn_453', 'cn_454', 'cn_455', 'cn_478', 'cn_479', 'cn_480', 'cn_481', 'cn_528', 'cn_535', 'cn_547', 'cn_563', 'cn_570', 'cn_578', 'cn_585', 'cn_592', 'cn_598'],
	'tc-pokemon-cn-35': ['cn_482', 'cn_483', 'cn_484', 'cn_485', 'cn_502', 'cn_503', 'cn_504', 'cn_505', 'cn_522', 'cn_529', 'cn_536', 'cn_548', 'cn_564', 'cn_571', 'cn_579', 'cn_586', 'cn_593', 'cn_599'],
	'tc-pokemon-cn-36': ['cn_486', 'cn_487', 'cn_488', 'cn_489', 'cn_506', 'cn_507', 'cn_508', 'cn_509', 'cn_523', 'cn_530', 'cn_549', 'cn_565', 'cn_572', 'cn_580', 'cn_587', 'cn_594', 'cn_600', 'cn_604'],
	'tc-pokemon-cn-37': ['cn_490', 'cn_491', 'cn_492', 'cn_493', 'cn_510', 'cn_511', 'cn_512', 'cn_513', 'cn_524', 'cn_531', 'cn_550', 'cn_566', 'cn_573', 'cn_581', 'cn_588', 'cn_595', 'cn_601', 'cn_605'],
	'tc-pokemon-cn-38': ['cn_494', 'cn_495', 'cn_496', 'cn_497', 'cn_514', 'cn_515', 'cn_516', 'cn_517', 'cn_525', 'cn_532', 'cn_551', 'cn_567', 'cn_574', 'cn_582', 'cn_589', 'cn_596', 'cn_602', 'cn_606'],
	'tc-pokemon-cn-39': ['cn_498', 'cn_499', 'cn_500', 'cn_501', 'cn_518', 'cn_519', 'cn_520', 'cn_521', 'cn_526', 'cn_533', 'cn_552', 'cn_568', 'cn_575', 'cn_583', 'cn_590', 'cn_597', 'cn_603', 'cn_607'],
	'tc-pokemon-cn-40': ['cn_608', 'cn_610', 'cn_612', 'cn_614', 'cn_616', 'cn_618', 'cn_620', 'cn_622', 'cn_648', 'cn_653', 'cn_658', 'cn_663', 'cn_668', 'cn_673', 'cn_678', 'cn_683', 'cn_688', 'cn_693'],
	'tc-pokemon-cn-41': ['cn_609', 'cn_611', 'cn_613', 'cn_615', 'cn_617', 'cn_619', 'cn_621', 'cn_623', 'cn_649', 'cn_654', 'cn_659', 'cn_664', 'cn_669', 'cn_674', 'cn_679', 'cn_684', 'cn_689', 'cn_694'],
	'tc-pokemon-cn-42': ['cn_624', 'cn_627', 'cn_630', 'cn_633', 'cn_636', 'cn_639', 'cn_642', 'cn_645', 'cn_650', 'cn_655', 'cn_660', 'cn_665', 'cn_670', 'cn_675', 'cn_680', 'cn_685', 'cn_690', 'cn_695'],
	'tc-pokemon-cn-43': ['cn_625', 'cn_628', 'cn_631', 'cn_634', 'cn_637', 'cn_640', 'cn_643', 'cn_646', 'cn_651', 'cn_656', 'cn_661', 'cn_666', 'cn_671', 'cn_676', 'cn_681', 'cn_686', 'cn_691', 'cn_696'],
	'tc-pokemon-cn-44': ['cn_626', 'cn_629', 'cn_632', 'cn_635', 'cn_638', 'cn_641', 'cn_644', 'cn_647', 'cn_652', 'cn_657', 'cn_662', 'cn_667', 'cn_672', 'cn_677', 'cn_682', 'cn_687', 'cn_692'],

	'tc-pokemon-cn_qd-01': ['cn_qd_01'],
	'tc-pokemon-cn_qd-02': ['cn_qd_553', 'cn_qd_652', 'cn_qd_717', 'cn_qd_782', 'cn_qd_991', 'cn_qd_1080', 'cn_qd_1157', 'cn_qd_1234', 'cn_qd_1733', 'cn_qd_1844', 'cn_qd_31_merge', 'cn_qd_48_merge', 'cn_qd_2411', 'cn_qd_2439', 'cn_qd_2467'],
	'tc-pokemon-cn_qd-03': ['cn_qd_554', 'cn_qd_653', 'cn_qd_718', 'cn_qd_783', 'cn_qd_992', 'cn_qd_1081', 'cn_qd_1158', 'cn_qd_1235', 'cn_qd_1734', 'cn_qd_1845', 'cn_qd_32_merge', 'cn_qd_49_merge', 'cn_qd_2412', 'cn_qd_2440', 'cn_qd_2468'],
	'tc-pokemon-cn_qd-04': ['cn_qd_555', 'cn_qd_654', 'cn_qd_719', 'cn_qd_784', 'cn_qd_993', 'cn_qd_1082', 'cn_qd_1159', 'cn_qd_1236', 'cn_qd_1735', 'cn_qd_1846', 'cn_qd_33_merge', 'cn_qd_50_merge', 'cn_qd_2413', 'cn_qd_2441', 'cn_qd_2469'],
	'tc-pokemon-cn_qd-05': ['cn_qd_556', 'cn_qd_655', 'cn_qd_720', 'cn_qd_785', 'cn_qd_994', 'cn_qd_1083', 'cn_qd_1160', 'cn_qd_1237', 'cn_qd_1736', 'cn_qd_1847', 'cn_qd_34_merge', 'cn_qd_51_merge', 'cn_qd_2414', 'cn_qd_2442', 'cn_qd_2470'],
	'tc-pokemon-cn_qd-06': ['cn_qd_557', 'cn_qd_656', 'cn_qd_721', 'cn_qd_786', 'cn_qd_995', 'cn_qd_1084', 'cn_qd_1161', 'cn_qd_1238', 'cn_qd_1737', 'cn_qd_1848', 'cn_qd_07_merge', 'cn_qd_35_merge', 'cn_qd_52_merge'],
	'tc-pokemon-cn_qd-07': ['cn_qd_558', 'cn_qd_657', 'cn_qd_722', 'cn_qd_787', 'cn_qd_996', 'cn_qd_1085', 'cn_qd_1162', 'cn_qd_1239', 'cn_qd_1738', 'cn_qd_1849', 'cn_qd_2221', 'cn_qd_08_merge', 'cn_qd_36_merge', 'cn_qd_53_merge'],
	'tc-pokemon-cn_qd-08': ['cn_qd_559', 'cn_qd_658', 'cn_qd_723', 'cn_qd_788', 'cn_qd_997', 'cn_qd_1086', 'cn_qd_1163', 'cn_qd_1240', 'cn_qd_1739', 'cn_qd_1850', 'cn_qd_2222', 'cn_qd_02_merge', 'cn_qd_2294', 'cn_qd_2319', 'cn_qd_37_merge', 'cn_qd_54_merge'],
	'tc-pokemon-cn_qd-09': ['cn_qd_560', 'cn_qd_659', 'cn_qd_724', 'cn_qd_789', 'cn_qd_998', 'cn_qd_1087', 'cn_qd_1164', 'cn_qd_1241', 'cn_qd_1740', 'cn_qd_1851', 'cn_qd_2223', 'cn_qd_03_merge', 'cn_qd_2295', 'cn_qd_2320', 'cn_qd_55_merge'],
	'tc-pokemon-cn_qd-10': ['cn_qd_530', 'cn_qd_561', 'cn_qd_660', 'cn_qd_725', 'cn_qd_790', 'cn_qd_999', 'cn_qd_1088', 'cn_qd_1165', 'cn_qd_1242', 'cn_qd_1741', 'cn_qd_1852', 'cn_qd_2224', 'cn_qd_04_merge', 'cn_qd_2296', 'cn_qd_2321', 'cn_qd_56_merge'],
	'tc-pokemon-cn_qd-11': ['cn_qd_531', 'cn_qd_562', 'cn_qd_661', 'cn_qd_726', 'cn_qd_791', 'cn_qd_1000', 'cn_qd_1089', 'cn_qd_1166', 'cn_qd_1243', 'cn_qd_1742', 'cn_qd_1853', 'cn_qd_2225', 'cn_qd_09_merge', 'cn_qd_2297', 'cn_qd_2322', 'cn_qd_57_merge'],
	'tc-pokemon-cn_qd-12': ['cn_qd_532', 'cn_qd_563', 'cn_qd_662', 'cn_qd_727', 'cn_qd_792', 'cn_qd_1001', 'cn_qd_1090', 'cn_qd_1167', 'cn_qd_1244', 'cn_qd_1743', 'cn_qd_1854', 'cn_qd_2226', 'cn_qd_01_merge', 'cn_qd_2298', 'cn_qd_2323', 'cn_qd_2341'],
	'tc-pokemon-cn_qd-13': ['cn_qd_533', 'cn_qd_564', 'cn_qd_663', 'cn_qd_728', 'cn_qd_793', 'cn_qd_1002', 'cn_qd_1091', 'cn_qd_1168', 'cn_qd_1245', 'cn_qd_1744', 'cn_qd_1855', 'cn_qd_2227', 'cn_qd_05_merge', 'cn_qd_11_merge', 'cn_qd_2299', 'cn_qd_2324'],
	'tc-pokemon-cn_qd-14': ['cn_qd_534', 'cn_qd_565', 'cn_qd_664', 'cn_qd_729', 'cn_qd_794', 'cn_qd_1003', 'cn_qd_1092', 'cn_qd_1169', 'cn_qd_1246', 'cn_qd_1745', 'cn_qd_1856', 'cn_qd_2228', 'cn_qd_06_merge', 'cn_qd_12_merge', 'cn_qd_2300', 'cn_qd_2325'],
	'tc-pokemon-cn_qd-15': ['cn_qd_535', 'cn_qd_566', 'cn_qd_665', 'cn_qd_730', 'cn_qd_795', 'cn_qd_1004', 'cn_qd_1093', 'cn_qd_1170', 'cn_qd_1247', 'cn_qd_1746', 'cn_qd_1857', 'cn_qd_2229', 'cn_qd_10_merge', 'cn_qd_13_merge', 'cn_qd_2301', 'cn_qd_2326'],
	'tc-pokemon-cn_qd-16': ['cn_qd_536', 'cn_qd_567', 'cn_qd_666', 'cn_qd_731', 'cn_qd_796', 'cn_qd_1005', 'cn_qd_1094', 'cn_qd_1171', 'cn_qd_1248', 'cn_qd_1747', 'cn_qd_1858', 'cn_qd_2230', 'cn_qd_14_merge', 'cn_qd_2302', 'cn_qd_2327', 'cn_qd_2342'],
	'tc-pokemon-cn_qd-17': ['cn_qd_537', 'cn_qd_568', 'cn_qd_667', 'cn_qd_732', 'cn_qd_797', 'cn_qd_1006', 'cn_qd_1095', 'cn_qd_1172', 'cn_qd_1249', 'cn_qd_1748', 'cn_qd_1859', 'cn_qd_2231', 'cn_qd_15_merge', 'cn_qd_2303', 'cn_qd_2328', 'cn_qd_2343'],
	'tc-pokemon-cn_qd-18': ['cn_qd_538', 'cn_qd_569', 'cn_qd_668', 'cn_qd_733', 'cn_qd_798', 'cn_qd_1007', 'cn_qd_1096', 'cn_qd_1173', 'cn_qd_1250', 'cn_qd_1749', 'cn_qd_1860', 'cn_qd_2232', 'cn_qd_16_merge', 'cn_qd_2304', 'cn_qd_2329', 'cn_qd_2344'],
	'tc-pokemon-cn_qd-19': ['cn_qd_539', 'cn_qd_570', 'cn_qd_669', 'cn_qd_734', 'cn_qd_799', 'cn_qd_1008', 'cn_qd_1097', 'cn_qd_1174', 'cn_qd_1251', 'cn_qd_1750', 'cn_qd_1861', 'cn_qd_2233', 'cn_qd_17_merge', 'cn_qd_2305', 'cn_qd_2330', 'cn_qd_2345'],
	'tc-pokemon-cn_qd-20': ['cn_qd_540', 'cn_qd_571', 'cn_qd_670', 'cn_qd_735', 'cn_qd_800', 'cn_qd_1009', 'cn_qd_1098', 'cn_qd_1175', 'cn_qd_1252', 'cn_qd_1751', 'cn_qd_1862', 'cn_qd_2234', 'cn_qd_18_merge', 'cn_qd_2306', 'cn_qd_2331', 'cn_qd_2346'],
	'tc-pokemon-cn_qd-21': ['cn_qd_541', 'cn_qd_572', 'cn_qd_671', 'cn_qd_736', 'cn_qd_801', 'cn_qd_1010', 'cn_qd_1099', 'cn_qd_1176', 'cn_qd_1253', 'cn_qd_1752', 'cn_qd_1863', 'cn_qd_2235', 'cn_qd_19_merge', 'cn_qd_2307', 'cn_qd_2332', 'cn_qd_2347'],
	'tc-pokemon-cn_qd-22': ['cn_qd_542', 'cn_qd_573', 'cn_qd_672', 'cn_qd_737', 'cn_qd_802', 'cn_qd_1011', 'cn_qd_1100', 'cn_qd_1177', 'cn_qd_1254', 'cn_qd_1753', 'cn_qd_1864', 'cn_qd_2236', 'cn_qd_20_merge', 'cn_qd_2308', 'cn_qd_2333', 'cn_qd_2348'],
	'tc-pokemon-cn_qd-23': ['cn_qd_543', 'cn_qd_574', 'cn_qd_673', 'cn_qd_738', 'cn_qd_803', 'cn_qd_1012', 'cn_qd_1101', 'cn_qd_1178', 'cn_qd_1255', 'cn_qd_1754', 'cn_qd_1865', 'cn_qd_2237', 'cn_qd_21_merge', 'cn_qd_2309', 'cn_qd_2334', 'cn_qd_2349'],
	'tc-pokemon-cn_qd-24': ['cn_qd_544', 'cn_qd_575', 'cn_qd_674', 'cn_qd_739', 'cn_qd_804', 'cn_qd_1013', 'cn_qd_1102', 'cn_qd_1179', 'cn_qd_1256', 'cn_qd_1755', 'cn_qd_1866', 'cn_qd_2238', 'cn_qd_22_merge', 'cn_qd_2310', 'cn_qd_2335', 'cn_qd_2350'],
	'tc-pokemon-cn_qd-25': ['cn_qd_545', 'cn_qd_576', 'cn_qd_675', 'cn_qd_740', 'cn_qd_805', 'cn_qd_1014', 'cn_qd_1103', 'cn_qd_1180', 'cn_qd_1257', 'cn_qd_1756', 'cn_qd_1867', 'cn_qd_2239', 'cn_qd_23_merge', 'cn_qd_2311', 'cn_qd_2336', 'cn_qd_2351'],
	'tc-pokemon-cn_qd-26': ['cn_qd_546', 'cn_qd_577', 'cn_qd_676', 'cn_qd_741', 'cn_qd_806', 'cn_qd_1015', 'cn_qd_1104', 'cn_qd_1181', 'cn_qd_1258', 'cn_qd_1757', 'cn_qd_1868', 'cn_qd_2240', 'cn_qd_24_merge', 'cn_qd_2312', 'cn_qd_2337', 'cn_qd_2352'],
	'tc-pokemon-cn_qd-27': ['cn_qd_547', 'cn_qd_578', 'cn_qd_677', 'cn_qd_742', 'cn_qd_807', 'cn_qd_1016', 'cn_qd_1105', 'cn_qd_1182', 'cn_qd_1259', 'cn_qd_1758', 'cn_qd_1869', 'cn_qd_2241', 'cn_qd_25_merge', 'cn_qd_2313', 'cn_qd_2338', 'cn_qd_2353'],
	'tc-pokemon-cn_qd-28': ['cn_qd_548', 'cn_qd_579', 'cn_qd_678', 'cn_qd_743', 'cn_qd_808', 'cn_qd_1017', 'cn_qd_1106', 'cn_qd_1183', 'cn_qd_1260', 'cn_qd_1759', 'cn_qd_1870', 'cn_qd_2242', 'cn_qd_26_merge', 'cn_qd_2314', 'cn_qd_2339', 'cn_qd_2398'],
	'tc-pokemon-cn_qd-29': ['cn_qd_549', 'cn_qd_580', 'cn_qd_679', 'cn_qd_744', 'cn_qd_809', 'cn_qd_1018', 'cn_qd_1107', 'cn_qd_1184', 'cn_qd_1261', 'cn_qd_1760', 'cn_qd_1871', 'cn_qd_2243', 'cn_qd_27_merge', 'cn_qd_2315', 'cn_qd_2340', 'cn_qd_2399'],
	'tc-pokemon-cn_qd-30': ['cn_qd_550', 'cn_qd_581', 'cn_qd_680', 'cn_qd_745', 'cn_qd_810', 'cn_qd_1019', 'cn_qd_1108', 'cn_qd_1185', 'cn_qd_1262', 'cn_qd_1761', 'cn_qd_1872', 'cn_qd_2244', 'cn_qd_28_merge', 'cn_qd_2316', 'cn_qd_38_merge', 'cn_qd_2400'],
	'tc-pokemon-cn_qd-31': ['cn_qd_551', 'cn_qd_582', 'cn_qd_681', 'cn_qd_746', 'cn_qd_811', 'cn_qd_1020', 'cn_qd_1109', 'cn_qd_1186', 'cn_qd_1263', 'cn_qd_1762', 'cn_qd_1873', 'cn_qd_2245', 'cn_qd_29_merge', 'cn_qd_2317', 'cn_qd_39_merge', 'cn_qd_2401'],
	'tc-pokemon-cn_qd-32': ['cn_qd_552', 'cn_qd_583', 'cn_qd_682', 'cn_qd_747', 'cn_qd_812', 'cn_qd_1021', 'cn_qd_1110', 'cn_qd_1187', 'cn_qd_1264', 'cn_qd_1763', 'cn_qd_1874', 'cn_qd_2246', 'cn_qd_30_merge', 'cn_qd_2318', 'cn_qd_40_merge', 'cn_qd_2402'],
	'tc-pokemon-cn_qd-33': ['cn_qd_584', 'cn_qd_589', 'cn_qd_683', 'cn_qd_748', 'cn_qd_813', 'cn_qd_1022', 'cn_qd_1111', 'cn_qd_1188', 'cn_qd_1265', 'cn_qd_1764', 'cn_qd_1875', 'cn_qd_2247', 'cn_qd_41_merge', 'cn_qd_78_merge', 'cn_qd_2381', 'cn_qd_2403'],
	'tc-pokemon-cn_qd-34': ['cn_qd_585', 'cn_qd_590', 'cn_qd_684', 'cn_qd_749', 'cn_qd_814', 'cn_qd_1023', 'cn_qd_1112', 'cn_qd_1189', 'cn_qd_1266', 'cn_qd_1765', 'cn_qd_1876', 'cn_qd_2248', 'cn_qd_42_merge', 'cn_qd_79_merge', 'cn_qd_2382', 'cn_qd_2404'],
	'tc-pokemon-cn_qd-35': ['cn_qd_586', 'cn_qd_591', 'cn_qd_685', 'cn_qd_750', 'cn_qd_815', 'cn_qd_1024', 'cn_qd_1113', 'cn_qd_1190', 'cn_qd_1267', 'cn_qd_1766', 'cn_qd_1877', 'cn_qd_2249', 'cn_qd_43_merge', 'cn_qd_80_merge', 'cn_qd_2383', 'cn_qd_2405'],
	'tc-pokemon-cn_qd-36': ['cn_qd_587', 'cn_qd_592', 'cn_qd_686', 'cn_qd_751', 'cn_qd_816', 'cn_qd_1025', 'cn_qd_1114', 'cn_qd_1191', 'cn_qd_1268', 'cn_qd_1767', 'cn_qd_1878', 'cn_qd_2250', 'cn_qd_44_merge', 'cn_qd_81_merge', 'cn_qd_2384', 'cn_qd_2406'],
	'tc-pokemon-cn_qd-37': ['cn_qd_588', 'cn_qd_593', 'cn_qd_687', 'cn_qd_752', 'cn_qd_817', 'cn_qd_1026', 'cn_qd_1115', 'cn_qd_1192', 'cn_qd_1269', 'cn_qd_1768', 'cn_qd_1879', 'cn_qd_2251', 'cn_qd_45_merge', 'cn_qd_82_merge', 'cn_qd_2385', 'cn_qd_2407'],
	'tc-pokemon-cn_qd-38': ['cn_qd_594', 'cn_qd_623', 'cn_qd_688', 'cn_qd_753', 'cn_qd_818', 'cn_qd_1027', 'cn_qd_1116', 'cn_qd_1193', 'cn_qd_1270', 'cn_qd_1769', 'cn_qd_1880', 'cn_qd_2252', 'cn_qd_46_merge', 'cn_qd_83_merge', 'cn_qd_2386', 'cn_qd_2408'],
	'tc-pokemon-cn_qd-39': ['cn_qd_595', 'cn_qd_624', 'cn_qd_689', 'cn_qd_754', 'cn_qd_819', 'cn_qd_1028', 'cn_qd_1117', 'cn_qd_1194', 'cn_qd_1271', 'cn_qd_1770', 'cn_qd_1881', 'cn_qd_2253', 'cn_qd_47_merge', 'cn_qd_84_merge', 'cn_qd_2387', 'cn_qd_2409'],
	'tc-pokemon-cn_qd-40': ['cn_qd_596', 'cn_qd_625', 'cn_qd_690', 'cn_qd_755', 'cn_qd_820', 'cn_qd_1029', 'cn_qd_1118', 'cn_qd_1195', 'cn_qd_1272', 'cn_qd_1771', 'cn_qd_1882', 'cn_qd_2254', 'cn_qd_85_merge', 'cn_qd_2388', 'cn_qd_2395', 'cn_qd_2410'],
	'tc-pokemon-cn_qd-41': ['cn_qd_597', 'cn_qd_626', 'cn_qd_691', 'cn_qd_756', 'cn_qd_821', 'cn_qd_1030', 'cn_qd_1119', 'cn_qd_1196', 'cn_qd_1273', 'cn_qd_1772', 'cn_qd_1883', 'cn_qd_2255', 'cn_qd_86_merge', 'cn_qd_2389', 'cn_qd_2396'],
	'tc-pokemon-cn_qd-42': ['cn_qd_598', 'cn_qd_627', 'cn_qd_692', 'cn_qd_757', 'cn_qd_822', 'cn_qd_1031', 'cn_qd_1120', 'cn_qd_1197', 'cn_qd_1274', 'cn_qd_1773', 'cn_qd_1884', 'cn_qd_2256', 'cn_qd_87_merge', 'cn_qd_2390', 'cn_qd_2397'],
	'tc-pokemon-cn_qd-43': ['cn_qd_599', 'cn_qd_628', 'cn_qd_693', 'cn_qd_758', 'cn_qd_823', 'cn_qd_1032', 'cn_qd_1121', 'cn_qd_1198', 'cn_qd_1275', 'cn_qd_1774', 'cn_qd_1885', 'cn_qd_2257', 'cn_qd_58_merge', 'cn_qd_68_merge', 'cn_qd_2415', 'cn_qd_2443'],
	'tc-pokemon-cn_qd-44': ['cn_qd_600', 'cn_qd_629', 'cn_qd_694', 'cn_qd_759', 'cn_qd_824', 'cn_qd_1033', 'cn_qd_1122', 'cn_qd_1199', 'cn_qd_1276', 'cn_qd_1775', 'cn_qd_1886', 'cn_qd_2258', 'cn_qd_59_merge', 'cn_qd_69_merge', 'cn_qd_2416', 'cn_qd_2444'],
	'tc-pokemon-cn_qd-45': ['cn_qd_601', 'cn_qd_630', 'cn_qd_695', 'cn_qd_760', 'cn_qd_825', 'cn_qd_1034', 'cn_qd_1123', 'cn_qd_1200', 'cn_qd_1277', 'cn_qd_1776', 'cn_qd_1887', 'cn_qd_2259', 'cn_qd_60_merge', 'cn_qd_70_merge', 'cn_qd_2417', 'cn_qd_2445'],
	'tc-pokemon-cn_qd-46': ['cn_qd_602', 'cn_qd_631', 'cn_qd_696', 'cn_qd_761', 'cn_qd_826', 'cn_qd_1035', 'cn_qd_1124', 'cn_qd_1201', 'cn_qd_1278', 'cn_qd_1777', 'cn_qd_1888', 'cn_qd_2260', 'cn_qd_61_merge', 'cn_qd_71_merge', 'cn_qd_2418', 'cn_qd_2446'],
	'tc-pokemon-cn_qd-47': ['cn_qd_603', 'cn_qd_632', 'cn_qd_697', 'cn_qd_762', 'cn_qd_827', 'cn_qd_1036', 'cn_qd_1125', 'cn_qd_1202', 'cn_qd_1279', 'cn_qd_1778', 'cn_qd_1889', 'cn_qd_2261', 'cn_qd_62_merge', 'cn_qd_72_merge', 'cn_qd_2419', 'cn_qd_2447'],
	'tc-pokemon-cn_qd-48': ['cn_qd_604', 'cn_qd_633', 'cn_qd_698', 'cn_qd_763', 'cn_qd_828', 'cn_qd_1037', 'cn_qd_1126', 'cn_qd_1203', 'cn_qd_1280', 'cn_qd_1779', 'cn_qd_1890', 'cn_qd_2262', 'cn_qd_63_merge', 'cn_qd_73_merge', 'cn_qd_2420', 'cn_qd_2448'],
	'tc-pokemon-cn_qd-49': ['cn_qd_605', 'cn_qd_634', 'cn_qd_699', 'cn_qd_764', 'cn_qd_829', 'cn_qd_1038', 'cn_qd_1127', 'cn_qd_1204', 'cn_qd_1281', 'cn_qd_1780', 'cn_qd_1891', 'cn_qd_2263', 'cn_qd_64_merge', 'cn_qd_74_merge', 'cn_qd_2421', 'cn_qd_2449'],
	'tc-pokemon-cn_qd-50': ['cn_qd_606', 'cn_qd_635', 'cn_qd_700', 'cn_qd_765', 'cn_qd_830', 'cn_qd_1039', 'cn_qd_1128', 'cn_qd_1205', 'cn_qd_1282', 'cn_qd_1781', 'cn_qd_1892', 'cn_qd_2264', 'cn_qd_65_merge', 'cn_qd_75_merge', 'cn_qd_2422', 'cn_qd_2450'],
	'tc-pokemon-cn_qd-51': ['cn_qd_607', 'cn_qd_636', 'cn_qd_701', 'cn_qd_766', 'cn_qd_831', 'cn_qd_1040', 'cn_qd_1129', 'cn_qd_1206', 'cn_qd_1283', 'cn_qd_1782', 'cn_qd_1893', 'cn_qd_2265', 'cn_qd_66_merge', 'cn_qd_76_merge', 'cn_qd_2423', 'cn_qd_2451'],
	'tc-pokemon-cn_qd-52': ['cn_qd_608', 'cn_qd_637', 'cn_qd_702', 'cn_qd_767', 'cn_qd_832', 'cn_qd_1041', 'cn_qd_1130', 'cn_qd_1207', 'cn_qd_1284', 'cn_qd_1783', 'cn_qd_1894', 'cn_qd_2266', 'cn_qd_67_merge', 'cn_qd_77_merge', 'cn_qd_2424', 'cn_qd_2452'],
	'tc-pokemon-cn_qd-53': ['cn_qd_609', 'cn_qd_638', 'cn_qd_703', 'cn_qd_768', 'cn_qd_833', 'cn_qd_1042', 'cn_qd_1131', 'cn_qd_1208', 'cn_qd_1285', 'cn_qd_1784', 'cn_qd_1895', 'cn_qd_2267', 'cn_qd_2391', 'cn_qd_2425', 'cn_qd_2453'],
	'tc-pokemon-cn_qd-54': ['cn_qd_610', 'cn_qd_639', 'cn_qd_704', 'cn_qd_769', 'cn_qd_834', 'cn_qd_1043', 'cn_qd_1132', 'cn_qd_1209', 'cn_qd_1286', 'cn_qd_1785', 'cn_qd_1896', 'cn_qd_2268', 'cn_qd_2392', 'cn_qd_2426', 'cn_qd_2454'],
	'tc-pokemon-cn_qd-55': ['cn_qd_611', 'cn_qd_640', 'cn_qd_705', 'cn_qd_770', 'cn_qd_835', 'cn_qd_1044', 'cn_qd_1133', 'cn_qd_1210', 'cn_qd_1287', 'cn_qd_1786', 'cn_qd_1897', 'cn_qd_2269', 'cn_qd_2393', 'cn_qd_2427', 'cn_qd_2455'],
	'tc-pokemon-cn_qd-56': ['cn_qd_612', 'cn_qd_641', 'cn_qd_706', 'cn_qd_771', 'cn_qd_836', 'cn_qd_1045', 'cn_qd_1134', 'cn_qd_1211', 'cn_qd_1288', 'cn_qd_1787', 'cn_qd_1898', 'cn_qd_2270', 'cn_qd_2394', 'cn_qd_2428', 'cn_qd_2456'],
	'tc-pokemon-cn_qd-57': ['cn_qd_613', 'cn_qd_642', 'cn_qd_707', 'cn_qd_772', 'cn_qd_837', 'cn_qd_1046', 'cn_qd_1135', 'cn_qd_1212', 'cn_qd_1289', 'cn_qd_1788', 'cn_qd_1899', 'cn_qd_2271', 'cn_qd_88_merge', 'cn_qd_98_merge', 'cn_qd_2429', 'cn_qd_2457'],
	'tc-pokemon-cn_qd-58': ['cn_qd_614', 'cn_qd_643', 'cn_qd_708', 'cn_qd_773', 'cn_qd_838', 'cn_qd_1047', 'cn_qd_1136', 'cn_qd_1213', 'cn_qd_1290', 'cn_qd_1789', 'cn_qd_1900', 'cn_qd_2272', 'cn_qd_89_merge', 'cn_qd_99_merge', 'cn_qd_2430', 'cn_qd_2458'],
	'tc-pokemon-cn_qd-59': ['cn_qd_615', 'cn_qd_644', 'cn_qd_709', 'cn_qd_774', 'cn_qd_839', 'cn_qd_1048', 'cn_qd_1137', 'cn_qd_1214', 'cn_qd_1291', 'cn_qd_1790', 'cn_qd_1901', 'cn_qd_2273', 'cn_qd_90_merge', 'cn_qd_100_merge', 'cn_qd_2431', 'cn_qd_2459'],
	'tc-pokemon-cn_qd-60': ['cn_qd_616', 'cn_qd_645', 'cn_qd_710', 'cn_qd_775', 'cn_qd_840', 'cn_qd_1049', 'cn_qd_1138', 'cn_qd_1215', 'cn_qd_1292', 'cn_qd_1791', 'cn_qd_1902', 'cn_qd_2274', 'cn_qd_91_merge', 'cn_qd_101_merge', 'cn_qd_2432', 'cn_qd_2460'],
	'tc-pokemon-cn_qd-61': ['cn_qd_617', 'cn_qd_646', 'cn_qd_711', 'cn_qd_776', 'cn_qd_841', 'cn_qd_1050', 'cn_qd_1139', 'cn_qd_1216', 'cn_qd_1293', 'cn_qd_1792', 'cn_qd_1903', 'cn_qd_2275', 'cn_qd_92_merge', 'cn_qd_102_merge', 'cn_qd_2433', 'cn_qd_2461'],
	'tc-pokemon-cn_qd-62': ['cn_qd_618', 'cn_qd_647', 'cn_qd_712', 'cn_qd_777', 'cn_qd_842', 'cn_qd_1051', 'cn_qd_1140', 'cn_qd_1217', 'cn_qd_1294', 'cn_qd_1793', 'cn_qd_1904', 'cn_qd_2276', 'cn_qd_93_merge', 'cn_qd_103_merge', 'cn_qd_2434', 'cn_qd_2462'],
	'tc-pokemon-cn_qd-63': ['cn_qd_619', 'cn_qd_648', 'cn_qd_713', 'cn_qd_778', 'cn_qd_843', 'cn_qd_1052', 'cn_qd_1141', 'cn_qd_1218', 'cn_qd_1295', 'cn_qd_1794', 'cn_qd_1905', 'cn_qd_2277', 'cn_qd_94_merge', 'cn_qd_104_merge', 'cn_qd_2435', 'cn_qd_2463'],
	'tc-pokemon-cn_qd-64': ['cn_qd_620', 'cn_qd_649', 'cn_qd_714', 'cn_qd_779', 'cn_qd_844', 'cn_qd_1053', 'cn_qd_1142', 'cn_qd_1219', 'cn_qd_1296', 'cn_qd_1795', 'cn_qd_1906', 'cn_qd_2278', 'cn_qd_95_merge', 'cn_qd_105_merge', 'cn_qd_2436', 'cn_qd_2464'],
	'tc-pokemon-cn_qd-65': ['cn_qd_621', 'cn_qd_650', 'cn_qd_715', 'cn_qd_780', 'cn_qd_845', 'cn_qd_1054', 'cn_qd_1143', 'cn_qd_1220', 'cn_qd_1297', 'cn_qd_1796', 'cn_qd_1907', 'cn_qd_2279', 'cn_qd_96_merge', 'cn_qd_106_merge', 'cn_qd_2437', 'cn_qd_2465'],
	'tc-pokemon-cn_qd-66': ['cn_qd_622', 'cn_qd_651', 'cn_qd_716', 'cn_qd_781', 'cn_qd_846', 'cn_qd_1055', 'cn_qd_1144', 'cn_qd_1221', 'cn_qd_1298', 'cn_qd_1797', 'cn_qd_1908', 'cn_qd_2280', 'cn_qd_97_merge', 'cn_qd_107_merge', 'cn_qd_2438', 'cn_qd_2466'],
	'tc-pokemon-cn_qd-67': ['cn_qd_847', 'cn_qd_848', 'cn_qd_849', 'cn_qd_894', 'cn_qd_895', 'cn_qd_896', 'cn_qd_897', 'cn_qd_942', 'cn_qd_943', 'cn_qd_944', 'cn_qd_945', 'cn_qd_990', 'cn_qd_1056', 'cn_qd_1057', 'cn_qd_1145', 'cn_qd_1222', 'cn_qd_1683', 'cn_qd_1798', 'cn_qd_1909', 'cn_qd_2281'],
	'tc-pokemon-cn_qd-68': ['cn_qd_850', 'cn_qd_851', 'cn_qd_852', 'cn_qd_853', 'cn_qd_898', 'cn_qd_899', 'cn_qd_900', 'cn_qd_901', 'cn_qd_946', 'cn_qd_947', 'cn_qd_948', 'cn_qd_949', 'cn_qd_1058', 'cn_qd_1059', 'cn_qd_1146', 'cn_qd_1223', 'cn_qd_1684', 'cn_qd_1799', 'cn_qd_1910', 'cn_qd_2282'],
	'tc-pokemon-cn_qd-69': ['cn_qd_854', 'cn_qd_855', 'cn_qd_856', 'cn_qd_857', 'cn_qd_902', 'cn_qd_903', 'cn_qd_904', 'cn_qd_905', 'cn_qd_950', 'cn_qd_951', 'cn_qd_952', 'cn_qd_953', 'cn_qd_1060', 'cn_qd_1061', 'cn_qd_1147', 'cn_qd_1224', 'cn_qd_1685', 'cn_qd_1800', 'cn_qd_1911', 'cn_qd_2283'],
	'tc-pokemon-cn_qd-70': ['cn_qd_858', 'cn_qd_859', 'cn_qd_860', 'cn_qd_861', 'cn_qd_906', 'cn_qd_907', 'cn_qd_908', 'cn_qd_909', 'cn_qd_954', 'cn_qd_955', 'cn_qd_956', 'cn_qd_957', 'cn_qd_1062', 'cn_qd_1063', 'cn_qd_1148', 'cn_qd_1225', 'cn_qd_1686', 'cn_qd_1801', 'cn_qd_1912', 'cn_qd_2284'],
	'tc-pokemon-cn_qd-71': ['cn_qd_862', 'cn_qd_863', 'cn_qd_864', 'cn_qd_865', 'cn_qd_910', 'cn_qd_911', 'cn_qd_912', 'cn_qd_913', 'cn_qd_958', 'cn_qd_959', 'cn_qd_960', 'cn_qd_961', 'cn_qd_1064', 'cn_qd_1065', 'cn_qd_1149', 'cn_qd_1226', 'cn_qd_1687', 'cn_qd_1802', 'cn_qd_1913', 'cn_qd_2285'],
	'tc-pokemon-cn_qd-72': ['cn_qd_866', 'cn_qd_867', 'cn_qd_868', 'cn_qd_869', 'cn_qd_914', 'cn_qd_915', 'cn_qd_916', 'cn_qd_917', 'cn_qd_962', 'cn_qd_963', 'cn_qd_964', 'cn_qd_965', 'cn_qd_1066', 'cn_qd_1067', 'cn_qd_1150', 'cn_qd_1227', 'cn_qd_1688', 'cn_qd_1803', 'cn_qd_1914', 'cn_qd_2286'],
	'tc-pokemon-cn_qd-73': ['cn_qd_870', 'cn_qd_871', 'cn_qd_872', 'cn_qd_873', 'cn_qd_918', 'cn_qd_919', 'cn_qd_920', 'cn_qd_921', 'cn_qd_966', 'cn_qd_967', 'cn_qd_968', 'cn_qd_969', 'cn_qd_1068', 'cn_qd_1069', 'cn_qd_1151', 'cn_qd_1228', 'cn_qd_1689', 'cn_qd_1804', 'cn_qd_1915', 'cn_qd_2287'],
	'tc-pokemon-cn_qd-74': ['cn_qd_874', 'cn_qd_875', 'cn_qd_876', 'cn_qd_877', 'cn_qd_922', 'cn_qd_923', 'cn_qd_924', 'cn_qd_925', 'cn_qd_970', 'cn_qd_971', 'cn_qd_972', 'cn_qd_973', 'cn_qd_1070', 'cn_qd_1071', 'cn_qd_1152', 'cn_qd_1229', 'cn_qd_1690', 'cn_qd_1805', 'cn_qd_1916', 'cn_qd_2288'],
	'tc-pokemon-cn_qd-75': ['cn_qd_878', 'cn_qd_879', 'cn_qd_880', 'cn_qd_881', 'cn_qd_926', 'cn_qd_927', 'cn_qd_928', 'cn_qd_929', 'cn_qd_974', 'cn_qd_975', 'cn_qd_976', 'cn_qd_977', 'cn_qd_1072', 'cn_qd_1073', 'cn_qd_1153', 'cn_qd_1230', 'cn_qd_1691', 'cn_qd_1806', 'cn_qd_1917', 'cn_qd_2289'],
	'tc-pokemon-cn_qd-76': ['cn_qd_882', 'cn_qd_883', 'cn_qd_884', 'cn_qd_885', 'cn_qd_930', 'cn_qd_931', 'cn_qd_932', 'cn_qd_933', 'cn_qd_978', 'cn_qd_979', 'cn_qd_980', 'cn_qd_981', 'cn_qd_1074', 'cn_qd_1075', 'cn_qd_1154', 'cn_qd_1231', 'cn_qd_1692', 'cn_qd_1807', 'cn_qd_1918', 'cn_qd_2290'],
	'tc-pokemon-cn_qd-77': ['cn_qd_886', 'cn_qd_887', 'cn_qd_888', 'cn_qd_889', 'cn_qd_934', 'cn_qd_935', 'cn_qd_936', 'cn_qd_937', 'cn_qd_982', 'cn_qd_983', 'cn_qd_984', 'cn_qd_985', 'cn_qd_1076', 'cn_qd_1077', 'cn_qd_1155', 'cn_qd_1232', 'cn_qd_1693', 'cn_qd_1808', 'cn_qd_1919', 'cn_qd_2291'],
	'tc-pokemon-cn_qd-78': ['cn_qd_890', 'cn_qd_891', 'cn_qd_892', 'cn_qd_893', 'cn_qd_938', 'cn_qd_939', 'cn_qd_940', 'cn_qd_941', 'cn_qd_986', 'cn_qd_987', 'cn_qd_988', 'cn_qd_989', 'cn_qd_1078', 'cn_qd_1079', 'cn_qd_1156', 'cn_qd_1233', 'cn_qd_1694', 'cn_qd_1809', 'cn_qd_1920', 'cn_qd_2292'],
	'tc-pokemon-cn_qd-79': ['cn_qd_1299', 'cn_qd_1309', 'cn_qd_1319', 'cn_qd_1329', 'cn_qd_1339', 'cn_qd_1349', 'cn_qd_1359', 'cn_qd_1369', 'cn_qd_1379', 'cn_qd_1389', 'cn_qd_1399', 'cn_qd_1409', 'cn_qd_1419', 'cn_qd_1429', 'cn_qd_1439', 'cn_qd_1449', 'cn_qd_1695', 'cn_qd_1810', 'cn_qd_1921', 'cn_qd_2293'],
	'tc-pokemon-cn_qd-80': ['cn_qd_1300', 'cn_qd_1310', 'cn_qd_1320', 'cn_qd_1330', 'cn_qd_1340', 'cn_qd_1350', 'cn_qd_1360', 'cn_qd_1370', 'cn_qd_1380', 'cn_qd_1390', 'cn_qd_1400', 'cn_qd_1410', 'cn_qd_1420', 'cn_qd_1430', 'cn_qd_1440', 'cn_qd_1450', 'cn_qd_1696', 'cn_qd_1811', 'cn_qd_1922'],
	'tc-pokemon-cn_qd-81': ['cn_qd_1301', 'cn_qd_1311', 'cn_qd_1321', 'cn_qd_1331', 'cn_qd_1341', 'cn_qd_1351', 'cn_qd_1361', 'cn_qd_1371', 'cn_qd_1381', 'cn_qd_1391', 'cn_qd_1401', 'cn_qd_1411', 'cn_qd_1421', 'cn_qd_1431', 'cn_qd_1441', 'cn_qd_1451', 'cn_qd_1697', 'cn_qd_1812', 'cn_qd_1923'],
	'tc-pokemon-cn_qd-82': ['cn_qd_1302', 'cn_qd_1312', 'cn_qd_1322', 'cn_qd_1332', 'cn_qd_1342', 'cn_qd_1352', 'cn_qd_1362', 'cn_qd_1372', 'cn_qd_1382', 'cn_qd_1392', 'cn_qd_1402', 'cn_qd_1412', 'cn_qd_1422', 'cn_qd_1432', 'cn_qd_1442', 'cn_qd_1452', 'cn_qd_1698', 'cn_qd_1813', 'cn_qd_1924'],
	'tc-pokemon-cn_qd-83': ['cn_qd_1303', 'cn_qd_1313', 'cn_qd_1323', 'cn_qd_1333', 'cn_qd_1343', 'cn_qd_1353', 'cn_qd_1363', 'cn_qd_1373', 'cn_qd_1383', 'cn_qd_1393', 'cn_qd_1403', 'cn_qd_1413', 'cn_qd_1423', 'cn_qd_1433', 'cn_qd_1443', 'cn_qd_1453', 'cn_qd_1699', 'cn_qd_1814', 'cn_qd_1925'],
	'tc-pokemon-cn_qd-84': ['cn_qd_1304', 'cn_qd_1314', 'cn_qd_1324', 'cn_qd_1334', 'cn_qd_1344', 'cn_qd_1354', 'cn_qd_1364', 'cn_qd_1374', 'cn_qd_1384', 'cn_qd_1394', 'cn_qd_1404', 'cn_qd_1414', 'cn_qd_1424', 'cn_qd_1434', 'cn_qd_1444', 'cn_qd_1454', 'cn_qd_1700', 'cn_qd_1815', 'cn_qd_1926'],
	'tc-pokemon-cn_qd-85': ['cn_qd_1305', 'cn_qd_1315', 'cn_qd_1325', 'cn_qd_1335', 'cn_qd_1345', 'cn_qd_1355', 'cn_qd_1365', 'cn_qd_1375', 'cn_qd_1385', 'cn_qd_1395', 'cn_qd_1405', 'cn_qd_1415', 'cn_qd_1425', 'cn_qd_1435', 'cn_qd_1445', 'cn_qd_1455', 'cn_qd_1701', 'cn_qd_1816', 'cn_qd_1927'],
	'tc-pokemon-cn_qd-86': ['cn_qd_1306', 'cn_qd_1316', 'cn_qd_1326', 'cn_qd_1336', 'cn_qd_1346', 'cn_qd_1356', 'cn_qd_1366', 'cn_qd_1376', 'cn_qd_1386', 'cn_qd_1396', 'cn_qd_1406', 'cn_qd_1416', 'cn_qd_1426', 'cn_qd_1436', 'cn_qd_1446', 'cn_qd_1456', 'cn_qd_1702', 'cn_qd_1817', 'cn_qd_1928'],
	'tc-pokemon-cn_qd-87': ['cn_qd_1307', 'cn_qd_1317', 'cn_qd_1327', 'cn_qd_1337', 'cn_qd_1347', 'cn_qd_1357', 'cn_qd_1367', 'cn_qd_1377', 'cn_qd_1387', 'cn_qd_1397', 'cn_qd_1407', 'cn_qd_1417', 'cn_qd_1427', 'cn_qd_1437', 'cn_qd_1447', 'cn_qd_1457', 'cn_qd_1703', 'cn_qd_1818', 'cn_qd_1929'],
	'tc-pokemon-cn_qd-88': ['cn_qd_1308', 'cn_qd_1318', 'cn_qd_1328', 'cn_qd_1338', 'cn_qd_1348', 'cn_qd_1358', 'cn_qd_1368', 'cn_qd_1378', 'cn_qd_1388', 'cn_qd_1398', 'cn_qd_1408', 'cn_qd_1418', 'cn_qd_1428', 'cn_qd_1438', 'cn_qd_1448', 'cn_qd_1458', 'cn_qd_1704', 'cn_qd_1819', 'cn_qd_1930'],
	'tc-pokemon-cn_qd-89': ['cn_qd_1459', 'cn_qd_1471', 'cn_qd_1483', 'cn_qd_1495', 'cn_qd_1507', 'cn_qd_1519', 'cn_qd_1531', 'cn_qd_1543', 'cn_qd_1555', 'cn_qd_1567', 'cn_qd_1579', 'cn_qd_1591', 'cn_qd_1603', 'cn_qd_1615', 'cn_qd_1627', 'cn_qd_1639', 'cn_qd_1705', 'cn_qd_1820', 'cn_qd_1931'],
	'tc-pokemon-cn_qd-90': ['cn_qd_1460', 'cn_qd_1472', 'cn_qd_1484', 'cn_qd_1496', 'cn_qd_1508', 'cn_qd_1520', 'cn_qd_1532', 'cn_qd_1544', 'cn_qd_1556', 'cn_qd_1568', 'cn_qd_1580', 'cn_qd_1592', 'cn_qd_1604', 'cn_qd_1616', 'cn_qd_1628', 'cn_qd_1640', 'cn_qd_1706', 'cn_qd_1821', 'cn_qd_1932'],
	'tc-pokemon-cn_qd-91': ['cn_qd_1461', 'cn_qd_1473', 'cn_qd_1485', 'cn_qd_1497', 'cn_qd_1509', 'cn_qd_1521', 'cn_qd_1533', 'cn_qd_1545', 'cn_qd_1557', 'cn_qd_1569', 'cn_qd_1581', 'cn_qd_1593', 'cn_qd_1605', 'cn_qd_1617', 'cn_qd_1629', 'cn_qd_1641', 'cn_qd_1707', 'cn_qd_1822', 'cn_qd_1933'],
	'tc-pokemon-cn_qd-92': ['cn_qd_1462', 'cn_qd_1474', 'cn_qd_1486', 'cn_qd_1498', 'cn_qd_1510', 'cn_qd_1522', 'cn_qd_1534', 'cn_qd_1546', 'cn_qd_1558', 'cn_qd_1570', 'cn_qd_1582', 'cn_qd_1594', 'cn_qd_1606', 'cn_qd_1618', 'cn_qd_1630', 'cn_qd_1642', 'cn_qd_1708', 'cn_qd_1823', 'cn_qd_1934'],
	'tc-pokemon-cn_qd-93': ['cn_qd_1463', 'cn_qd_1475', 'cn_qd_1487', 'cn_qd_1499', 'cn_qd_1511', 'cn_qd_1523', 'cn_qd_1535', 'cn_qd_1547', 'cn_qd_1559', 'cn_qd_1571', 'cn_qd_1583', 'cn_qd_1595', 'cn_qd_1607', 'cn_qd_1619', 'cn_qd_1631', 'cn_qd_1643', 'cn_qd_1709', 'cn_qd_1824', 'cn_qd_1935'],
	'tc-pokemon-cn_qd-94': ['cn_qd_1464', 'cn_qd_1476', 'cn_qd_1488', 'cn_qd_1500', 'cn_qd_1512', 'cn_qd_1524', 'cn_qd_1536', 'cn_qd_1548', 'cn_qd_1560', 'cn_qd_1572', 'cn_qd_1584', 'cn_qd_1596', 'cn_qd_1608', 'cn_qd_1620', 'cn_qd_1632', 'cn_qd_1644', 'cn_qd_1710', 'cn_qd_1825', 'cn_qd_1936'],
	'tc-pokemon-cn_qd-95': ['cn_qd_1465', 'cn_qd_1477', 'cn_qd_1489', 'cn_qd_1501', 'cn_qd_1513', 'cn_qd_1525', 'cn_qd_1537', 'cn_qd_1549', 'cn_qd_1561', 'cn_qd_1573', 'cn_qd_1585', 'cn_qd_1597', 'cn_qd_1609', 'cn_qd_1621', 'cn_qd_1633', 'cn_qd_1645', 'cn_qd_1711', 'cn_qd_1826', 'cn_qd_1937'],
	'tc-pokemon-cn_qd-96': ['cn_qd_1466', 'cn_qd_1478', 'cn_qd_1490', 'cn_qd_1502', 'cn_qd_1514', 'cn_qd_1526', 'cn_qd_1538', 'cn_qd_1550', 'cn_qd_1562', 'cn_qd_1574', 'cn_qd_1586', 'cn_qd_1598', 'cn_qd_1610', 'cn_qd_1622', 'cn_qd_1634', 'cn_qd_1646', 'cn_qd_1712', 'cn_qd_1827', 'cn_qd_1938'],
	'tc-pokemon-cn_qd-97': ['cn_qd_1467', 'cn_qd_1479', 'cn_qd_1491', 'cn_qd_1503', 'cn_qd_1515', 'cn_qd_1527', 'cn_qd_1539', 'cn_qd_1551', 'cn_qd_1563', 'cn_qd_1575', 'cn_qd_1587', 'cn_qd_1599', 'cn_qd_1611', 'cn_qd_1623', 'cn_qd_1635', 'cn_qd_1647', 'cn_qd_1713', 'cn_qd_1828', 'cn_qd_1939'],
	'tc-pokemon-cn_qd-98': ['cn_qd_1468', 'cn_qd_1480', 'cn_qd_1492', 'cn_qd_1504', 'cn_qd_1516', 'cn_qd_1528', 'cn_qd_1540', 'cn_qd_1552', 'cn_qd_1564', 'cn_qd_1576', 'cn_qd_1588', 'cn_qd_1600', 'cn_qd_1612', 'cn_qd_1624', 'cn_qd_1636', 'cn_qd_1648', 'cn_qd_1714', 'cn_qd_1829', 'cn_qd_1940'],
	'tc-pokemon-cn_qd-99': ['cn_qd_1469', 'cn_qd_1481', 'cn_qd_1493', 'cn_qd_1505', 'cn_qd_1517', 'cn_qd_1529', 'cn_qd_1541', 'cn_qd_1553', 'cn_qd_1565', 'cn_qd_1577', 'cn_qd_1589', 'cn_qd_1601', 'cn_qd_1613', 'cn_qd_1625', 'cn_qd_1637', 'cn_qd_1649', 'cn_qd_1715', 'cn_qd_1830', 'cn_qd_1941'],
	'tc-pokemon-cn_qd-100': ['cn_qd_1470', 'cn_qd_1482', 'cn_qd_1494', 'cn_qd_1506', 'cn_qd_1518', 'cn_qd_1530', 'cn_qd_1542', 'cn_qd_1554', 'cn_qd_1566', 'cn_qd_1578', 'cn_qd_1590', 'cn_qd_1602', 'cn_qd_1614', 'cn_qd_1626', 'cn_qd_1638', 'cn_qd_1650', 'cn_qd_1716', 'cn_qd_1831', 'cn_qd_1942'],
	'tc-pokemon-cn_qd-101': ['cn_qd_1651', 'cn_qd_1655', 'cn_qd_1659', 'cn_qd_1663', 'cn_qd_1667', 'cn_qd_1671', 'cn_qd_1675', 'cn_qd_1679', 'cn_qd_1717', 'cn_qd_1721', 'cn_qd_1725', 'cn_qd_1729', 'cn_qd_1832', 'cn_qd_1836', 'cn_qd_1840', 'cn_qd_1943', 'cn_qd_2354', 'cn_qd_2376'],
	'tc-pokemon-cn_qd-102': ['cn_qd_1652', 'cn_qd_1656', 'cn_qd_1660', 'cn_qd_1664', 'cn_qd_1668', 'cn_qd_1672', 'cn_qd_1676', 'cn_qd_1680', 'cn_qd_1718', 'cn_qd_1722', 'cn_qd_1726', 'cn_qd_1730', 'cn_qd_1833', 'cn_qd_1837', 'cn_qd_1841', 'cn_qd_1944', 'cn_qd_2355', 'cn_qd_2377'],
	'tc-pokemon-cn_qd-103': ['cn_qd_1653', 'cn_qd_1657', 'cn_qd_1661', 'cn_qd_1665', 'cn_qd_1669', 'cn_qd_1673', 'cn_qd_1677', 'cn_qd_1681', 'cn_qd_1719', 'cn_qd_1723', 'cn_qd_1727', 'cn_qd_1731', 'cn_qd_1834', 'cn_qd_1838', 'cn_qd_1842', 'cn_qd_1945', 'cn_qd_2356', 'cn_qd_2378'],
	'tc-pokemon-cn_qd-104': ['cn_qd_1654', 'cn_qd_1658', 'cn_qd_1662', 'cn_qd_1666', 'cn_qd_1670', 'cn_qd_1674', 'cn_qd_1678', 'cn_qd_1682', 'cn_qd_1720', 'cn_qd_1724', 'cn_qd_1728', 'cn_qd_1732', 'cn_qd_1835', 'cn_qd_1839', 'cn_qd_1843', 'cn_qd_1946', 'cn_qd_2357', 'cn_qd_2379'],

	'tc-pokemon-cn_qd-105': ['cn_qd_1947', 'cn_qd_1955', 'cn_qd_1963', 'cn_qd_1971', 'cn_qd_1979', 'cn_qd_1987', 'cn_qd_1995', 'cn_qd_2003', 'cn_qd_2100', 'cn_qd_2118', 'cn_qd_2136', 'cn_qd_2154', 'cn_qd_2172', 'cn_qd_2190', 'cn_qd_2208', 'cn_qd_2096', 'cn_qd_2358', 'cn_qd_2380'],
	'tc-pokemon-cn_qd-106': ['cn_qd_1948', 'cn_qd_1956', 'cn_qd_1964', 'cn_qd_1972', 'cn_qd_1980', 'cn_qd_1988', 'cn_qd_1996', 'cn_qd_2004', 'cn_qd_2101', 'cn_qd_2119', 'cn_qd_2137', 'cn_qd_2155', 'cn_qd_2173', 'cn_qd_2191', 'cn_qd_2209', 'cn_qd_2097', 'cn_qd_2359'],
	'tc-pokemon-cn_qd-107': ['cn_qd_1949', 'cn_qd_1957', 'cn_qd_1965', 'cn_qd_1973', 'cn_qd_1981', 'cn_qd_1989', 'cn_qd_1997', 'cn_qd_2005', 'cn_qd_2102', 'cn_qd_2120', 'cn_qd_2138', 'cn_qd_2156', 'cn_qd_2174', 'cn_qd_2192', 'cn_qd_2210', 'cn_qd_2098', 'cn_qd_2360'],
	'tc-pokemon-cn_qd-108': ['cn_qd_1950', 'cn_qd_1958', 'cn_qd_1966', 'cn_qd_1974', 'cn_qd_1982', 'cn_qd_1990', 'cn_qd_1998', 'cn_qd_2006', 'cn_qd_2103', 'cn_qd_2121', 'cn_qd_2139', 'cn_qd_2157', 'cn_qd_2175', 'cn_qd_2193', 'cn_qd_2211', 'cn_qd_2099', 'cn_qd_2361'],
	'tc-pokemon-cn_qd-109': ['cn_qd_1951', 'cn_qd_1959', 'cn_qd_1967', 'cn_qd_1975', 'cn_qd_1983', 'cn_qd_1991', 'cn_qd_1999', 'cn_qd_2007', 'cn_qd_2104', 'cn_qd_2122', 'cn_qd_2140', 'cn_qd_2158', 'cn_qd_2176', 'cn_qd_2194', 'cn_qd_2212', 'cn_qd_2362'],
	'tc-pokemon-cn_qd-110': ['cn_qd_1952', 'cn_qd_1960', 'cn_qd_1968', 'cn_qd_1976', 'cn_qd_1984', 'cn_qd_1992', 'cn_qd_2000', 'cn_qd_2008', 'cn_qd_2105', 'cn_qd_2123', 'cn_qd_2141', 'cn_qd_2159', 'cn_qd_2177', 'cn_qd_2195', 'cn_qd_2213', 'cn_qd_2363'],
	'tc-pokemon-cn_qd-111': ['cn_qd_1953', 'cn_qd_1961', 'cn_qd_1969', 'cn_qd_1977', 'cn_qd_1985', 'cn_qd_1993', 'cn_qd_2001', 'cn_qd_2009', 'cn_qd_2106', 'cn_qd_2124', 'cn_qd_2142', 'cn_qd_2160', 'cn_qd_2178', 'cn_qd_2196', 'cn_qd_2214', 'cn_qd_2364'],
	'tc-pokemon-cn_qd-112': ['cn_qd_1954', 'cn_qd_1962', 'cn_qd_1970', 'cn_qd_1978', 'cn_qd_1986', 'cn_qd_1994', 'cn_qd_2002', 'cn_qd_2010', 'cn_qd_2107', 'cn_qd_2125', 'cn_qd_2143', 'cn_qd_2161', 'cn_qd_2179', 'cn_qd_2197', 'cn_qd_2215', 'cn_qd_2365'],
	'tc-pokemon-cn_qd-113': ['cn_qd_2011', 'cn_qd_2021', 'cn_qd_2031', 'cn_qd_2041', 'cn_qd_2051', 'cn_qd_2061', 'cn_qd_2071', 'cn_qd_2081', 'cn_qd_2108', 'cn_qd_2126', 'cn_qd_2144', 'cn_qd_2162', 'cn_qd_2180', 'cn_qd_2198', 'cn_qd_2216', 'cn_qd_2366'],
	'tc-pokemon-cn_qd-114': ['cn_qd_2012', 'cn_qd_2022', 'cn_qd_2032', 'cn_qd_2042', 'cn_qd_2052', 'cn_qd_2062', 'cn_qd_2072', 'cn_qd_2082', 'cn_qd_2109', 'cn_qd_2127', 'cn_qd_2145', 'cn_qd_2163', 'cn_qd_2181', 'cn_qd_2199', 'cn_qd_2217', 'cn_qd_2367'],
	'tc-pokemon-cn_qd-115': ['cn_qd_2013', 'cn_qd_2023', 'cn_qd_2033', 'cn_qd_2043', 'cn_qd_2053', 'cn_qd_2063', 'cn_qd_2073', 'cn_qd_2083', 'cn_qd_2110', 'cn_qd_2128', 'cn_qd_2146', 'cn_qd_2164', 'cn_qd_2182', 'cn_qd_2200', 'cn_qd_2218', 'cn_qd_2368'],
	'tc-pokemon-cn_qd-116': ['cn_qd_2014', 'cn_qd_2024', 'cn_qd_2034', 'cn_qd_2044', 'cn_qd_2054', 'cn_qd_2064', 'cn_qd_2074', 'cn_qd_2084', 'cn_qd_2111', 'cn_qd_2129', 'cn_qd_2147', 'cn_qd_2165', 'cn_qd_2183', 'cn_qd_2201', 'cn_qd_2219', 'cn_qd_2369'],
	'tc-pokemon-cn_qd-117': ['cn_qd_2015', 'cn_qd_2025', 'cn_qd_2035', 'cn_qd_2045', 'cn_qd_2055', 'cn_qd_2065', 'cn_qd_2075', 'cn_qd_2085', 'cn_qd_2112', 'cn_qd_2130', 'cn_qd_2148', 'cn_qd_2166', 'cn_qd_2184', 'cn_qd_2202', 'cn_qd_2220', 'cn_qd_2370'],
	'tc-pokemon-cn_qd-118': ['cn_qd_2016', 'cn_qd_2026', 'cn_qd_2036', 'cn_qd_2046', 'cn_qd_2056', 'cn_qd_2066', 'cn_qd_2076', 'cn_qd_2086', 'cn_qd_2113', 'cn_qd_2131', 'cn_qd_2149', 'cn_qd_2167', 'cn_qd_2185', 'cn_qd_2203', 'cn_qd_2091', 'cn_qd_2371'],
	'tc-pokemon-cn_qd-119': ['cn_qd_2017', 'cn_qd_2027', 'cn_qd_2037', 'cn_qd_2047', 'cn_qd_2057', 'cn_qd_2067', 'cn_qd_2077', 'cn_qd_2087', 'cn_qd_2114', 'cn_qd_2132', 'cn_qd_2150', 'cn_qd_2168', 'cn_qd_2186', 'cn_qd_2204', 'cn_qd_2092', 'cn_qd_2372'],
	'tc-pokemon-cn_qd-120': ['cn_qd_2018', 'cn_qd_2028', 'cn_qd_2038', 'cn_qd_2048', 'cn_qd_2058', 'cn_qd_2068', 'cn_qd_2078', 'cn_qd_2088', 'cn_qd_2115', 'cn_qd_2133', 'cn_qd_2151', 'cn_qd_2169', 'cn_qd_2187', 'cn_qd_2205', 'cn_qd_2093', 'cn_qd_2373'],
	'tc-pokemon-cn_qd-121': ['cn_qd_2019', 'cn_qd_2029', 'cn_qd_2039', 'cn_qd_2049', 'cn_qd_2059', 'cn_qd_2069', 'cn_qd_2079', 'cn_qd_2089', 'cn_qd_2116', 'cn_qd_2134', 'cn_qd_2152', 'cn_qd_2170', 'cn_qd_2188', 'cn_qd_2206', 'cn_qd_2094', 'cn_qd_2374'],
	'tc-pokemon-cn_qd-122': ['cn_qd_2020', 'cn_qd_2030', 'cn_qd_2040', 'cn_qd_2050', 'cn_qd_2060', 'cn_qd_2070', 'cn_qd_2080', 'cn_qd_2090', 'cn_qd_2117', 'cn_qd_2135', 'cn_qd_2153', 'cn_qd_2171', 'cn_qd_2189', 'cn_qd_2207', 'cn_qd_2095', 'cn_qd_2375'],

	'tc-pokemon-cn_qd-123': ['cn_qd_2471', 'cn_qd_2476', 'cn_qd_2481', 'cn_qd_2486', 'cn_qd_2491', 'cn_qd_2496', 'cn_qd_2501', 'cn_qd_2506'],
	'tc-pokemon-cn_qd-124': ['cn_qd_2472', 'cn_qd_2477', 'cn_qd_2482', 'cn_qd_2487', 'cn_qd_2492', 'cn_qd_2497', 'cn_qd_2502', 'cn_qd_2507'],
	'tc-pokemon-cn_qd-125': ['cn_qd_2473', 'cn_qd_2478', 'cn_qd_2483', 'cn_qd_2488', 'cn_qd_2493', 'cn_qd_2498', 'cn_qd_2503', 'cn_qd_2508'],
	'tc-pokemon-cn_qd-126': ['cn_qd_2474', 'cn_qd_2479', 'cn_qd_2484', 'cn_qd_2489', 'cn_qd_2494', 'cn_qd_2499', 'cn_qd_2504', 'cn_qd_2509'],
	'tc-pokemon-cn_qd-127': ['cn_qd_2475', 'cn_qd_2480', 'cn_qd_2485', 'cn_qd_2490', 'cn_qd_2495', 'cn_qd_2500', 'cn_qd_2505', 'cn_qd_2510'],

	'xy-pokemon-cn-01': ['xy_01', 'xy_05', 'xy_09', 'xy_13', 'xy_17', 'xy_21', 'xy_25', 'xy_29'],
	'xy-pokemon-cn-02': ['xy_02', 'xy_06', 'xy_10', 'xy_14', 'xy_18', 'xy_22', 'xy_26', 'xy_30'],
	'xy-pokemon-cn-03': ['xy_03', 'xy_07', 'xy_11', 'xy_15', 'xy_19', 'xy_23', 'xy_27', 'xy_31'],
	'xy-pokemon-cn-04': ['xy_04', 'xy_08', 'xy_12', 'xy_16', 'xy_20', 'xy_24', 'xy_28', 'xy_32'],
	'xy-pokemon-cn-05': ['xy_33', 'xy_35', 'xy_37', 'xy_39', 'xy_41', 'xy_43', 'xy_45', 'xy_47'],
	'xy-pokemon-cn-06': ['xy_34', 'xy_36', 'xy_38', 'xy_40', 'xy_42', 'xy_44', 'xy_46', 'xy_48'],
	'xy-pokemon-cn-07': ['xy_49', 'xy_51', 'xy_53', 'xy_55', 'xy_57', 'xy_59', 'xy_61', 'xy_63'],
	'xy-pokemon-cn-08': ['xy_50', 'xy_52', 'xy_54', 'xy_56', 'xy_58', 'xy_60', 'xy_62', 'xy_64'],
	'xy-pokemon-cn-09': ['xy_65', 'xy_67', 'xy_69', 'xy_71', 'xy_73', 'xy_75', 'xy_77', 'xy_79'],
	'xy-pokemon-cn-10': ['xy_66', 'xy_68', 'xy_70', 'xy_72', 'xy_74', 'xy_76', 'xy_78', 'xy_80'],

	'tc-pokemon-kr-01': ['kr_17_merge', 'kr_18_merge', 'kr_19_merge', 'kr_20_merge'],
	'tc-pokemon-kr-02': ['kr_21_merge', 'kr_22_merge', 'kr_23_merge', 'kr_52'],
	'tc-pokemon-kr-03': [],
	'tc-pokemon-kr-04': [],
	'tc-pokemon-kr-05': [],
	'tc-pokemon-kr-06': [],
	'tc-pokemon-kr-07': [],
	'tc-pokemon-kr-08': [],
	'tc-pokemon-kr-09': [],
	'tc-pokemon-kr-10': [],

	'tc-pokemon-en-01': ['en_01', 'en_04', 'en_07', 'en_10', 'en_13', 'en_16', 'en_115', 'en_134'],
	'tc-pokemon-en-02': ['en_02', 'en_05', 'en_08', 'en_11', 'en_14', 'en_17', 'en_116', 'en_135'],
	'tc-pokemon-en-03': ['en_03', 'en_06', 'en_09', 'en_12', 'en_15', 'en_18', 'en_117', 'en_136'],
	'tc-pokemon-en-04': ['en_25', 'en_29', 'en_33', 'en_37', 'en_41', 'en_45', 'en_118', 'en_137'],
	'tc-pokemon-en-05': ['en_26', 'en_30', 'en_34', 'en_38', 'en_42', 'en_46', 'en_119', 'en_138'],
	'tc-pokemon-en-06': ['en_27', 'en_31', 'en_35', 'en_39', 'en_43', 'en_47', 'en_120', 'en_139'],
	'tc-pokemon-en-07': ['en_28', 'en_32', 'en_36', 'en_40', 'en_44', 'en_48', 'en_121', 'en_140'],
	'tc-pokemon-en-08': ['en_57', 'en_61', 'en_65', 'en_69', 'en_73', 'en_77', 'en_122', 'en_141'],
	'tc-pokemon-en-09': ['en_58', 'en_62', 'en_66', 'en_70', 'en_74', 'en_78', 'en_123', 'en_142'],
	'tc-pokemon-en-10': ['en_59', 'en_63', 'en_67', 'en_71', 'en_75', 'en_79', 'en_124', 'en_143'],
	'tc-pokemon-en-11': ['en_60', 'en_64', 'en_68', 'en_72', 'en_76', 'en_80', 'en_125', 'en_144'],
	'tc-pokemon-en-12': ['en_19', 'en_23', 'en_51', 'en_55', 'en_83', 'en_87', 'en_126', 'en_145'],
	'tc-pokemon-en-13': ['en_20', 'en_24', 'en_52', 'en_56', 'en_84', 'en_88', 'en_127', 'en_146'],
	'tc-pokemon-en-14': ['en_21', 'en_49', 'en_53', 'en_81', 'en_85', 'en_89', 'en_128', 'en_147'],
	'tc-pokemon-en-15': ['en_22', 'en_50', 'en_54', 'en_82', 'en_86', 'en_90', 'en_129', 'en_148'],
	'tc-pokemon-en-16': ['en_91', 'en_95', 'en_99', 'en_103', 'en_107', 'en_111', 'en_130', 'en_149'],
	'tc-pokemon-en-17': ['en_92', 'en_96', 'en_100', 'en_104', 'en_108', 'en_112', 'en_131', 'en_150'],
	'tc-pokemon-en-18': ['en_93', 'en_97', 'en_101', 'en_105', 'en_109', 'en_113', 'en_132', 'en_151'],
	'tc-pokemon-en-19': ['en_94', 'en_98', 'en_102', 'en_106', 'en_110', 'en_114', 'en_133', 'en_152'],

	'ks-pokemon-tw-01': ['tw_17', 'tw_19', 'tw_21', 'tw_23', 'tw_01_merge', 'tw_03_merge', 'tw_05_merge'],
	'ks-pokemon-tw-02': ['tw_16', 'tw_18', 'tw_20', 'tw_22', 'tw_24', 'tw_02_merge', 'tw_04_merge'],
	'ks-pokemon-tw-03': ['tw_25', 'tw_27', 'tw_29', 'tw_31', 'tw_41', 'tw_45', 'tw_49', 'tw_57', 'tw_65', 'tw_71', 'tw_97', 'tw_105'],
	'ks-pokemon-tw-04': ['tw_26', 'tw_28', 'tw_30', 'tw_32', 'tw_42', 'tw_46', 'tw_50', 'tw_58', 'tw_66', 'tw_72', 'tw_98', 'tw_106'],
	'ks-pokemon-tw-05': ['tw_33', 'tw_35', 'tw_37', 'tw_39', 'tw_43', 'tw_47', 'tw_51', 'tw_59', 'tw_67', 'tw_73', 'tw_99', 'tw_107'],
	'ks-pokemon-tw-06': ['tw_34', 'tw_36', 'tw_38', 'tw_40', 'tw_44', 'tw_48', 'tw_52', 'tw_60', 'tw_68', 'tw_74', 'tw_100', 'tw_108'],
	'ks-pokemon-tw-07': ['tw_53', 'tw_55', 'tw_61', 'tw_63', 'tw_69', 'tw_75', 'tw_77', 'tw_79', 'tw_81', 'tw_85', 'tw_101', 'tw_109'],
	'ks-pokemon-tw-08': ['tw_54', 'tw_56', 'tw_62', 'tw_64', 'tw_70', 'tw_76', 'tw_78', 'tw_80', 'tw_82', 'tw_86', 'tw_102', 'tw_110'],
	'ks-pokemon-tw-09': ['tw_83', 'tw_87', 'tw_89', 'tw_91', 'tw_93', 'tw_95', 'tw_103', 'tw_111', 'tw_121', 'tw_125'],
	'ks-pokemon-tw-10': ['tw_84', 'tw_88', 'tw_90', 'tw_92', 'tw_94', 'tw_96', 'tw_104', 'tw_112', 'tw_122', 'tw_126'],
	'ks-pokemon-tw-11': ['tw_113', 'tw_115', 'tw_117', 'tw_119', 'tw_123', 'tw_127'],
	'ks-pokemon-tw-12': ['tw_114', 'tw_116', 'tw_118', 'tw_120', 'tw_124', 'tw_128'],

}


CrossIDMap = {
	'tc-pokemon-cn-07': ['cn_01', 'cn_15', 'cn_53', 'cn_79'],
	'tc-pokemon-cn-08': ['cn_02', 'cn_16', 'cn_54', 'cn_80'],
	'tc-pokemon-cn-09': ['cn_03', 'cn_17', 'cn_55', 'cn_81'],
	'tc-pokemon-cn-10': ['cn_04', 'cn_18', 'cn_56', 'cn_82'],
	'tc-pokemon-cn-11': ['cn_05', 'cn_19', 'cn_57', 'cn_83'],
	'tc-pokemon-cn-12': ['cn_06', 'cn_20', 'cn_58', 'cn_84'],
	'tc-pokemon-cn-13': ['cn_07', 'cn_21', 'cn_59', 'cn_85'],
	'tc-pokemon-cn-14': ['cn_08', 'cn_22', 'cn_60', 'cn_86'],
	'tc-pokemon-cn-15': ['cn_09', 'cn_23', 'cn_61', 'cn_87'],
	'tc-pokemon-cn-16': ['cn_10', 'cn_24', 'cn_62', 'cn_88'],
	'tc-pokemon-cn-17': ['cn_11', 'cn_25', 'cn_63', 'cn_89'],
	'tc-pokemon-cn-18': ['cn_12', 'cn_26', 'cn_64', 'cn_90'],
	'tc-pokemon-cn-19': ['cn_13', 'cn_27', 'cn_65', 'cn_91'],
	'tc-pokemon-cn-20': ['cn_14', 'cn_28', 'cn_66', 'cn_92'],
	'tc-pokemon-cn-21': ['cn_29', 'cn_30', 'cn_67', 'cn_93'],
	'tc-pokemon-cn-22': ['cn_31', 'cn_32', 'cn_68', 'cn_94'],
	'tc-pokemon-cn-23': ['cn_33', 'cn_34', 'cn_69', 'cn_95'],
	'tc-pokemon-cn-24': ['cn_35', 'cn_36', 'cn_70', 'cn_96'],
	'tc-pokemon-cn-25': ['cn_37', 'cn_38', 'cn_71', 'cn_97'],
	'tc-pokemon-cn-26': ['cn_39', 'cn_40', 'cn_72'],
	'tc-pokemon-cn-27': ['cn_41', 'cn_42', 'cn_73'],
	'tc-pokemon-cn-28': ['cn_43', 'cn_44', 'cn_74'],
	'tc-pokemon-cn-29': ['cn_45', 'cn_46', 'cn_75'],
	'tc-pokemon-cn-30': ['cn_47', 'cn_48', 'cn_76'],
	'tc-pokemon-cn-31': ['cn_49', 'cn_50', 'cn_77'],
	'tc-pokemon-cn-32': ['cn_51', 'cn_52', 'cn_78'],

	'tc-pokemon-cn_qd-02': ['cn_qd_01', 'cn_qd_51', 'cn_qd_207', 'cn_qd_309'],
	'tc-pokemon-cn_qd-03': ['cn_qd_02', 'cn_qd_52', 'cn_qd_208', 'cn_qd_310'],
	'tc-pokemon-cn_qd-04': ['cn_qd_03', 'cn_qd_53', 'cn_qd_209', 'cn_qd_311'],
	'tc-pokemon-cn_qd-05': ['cn_qd_04', 'cn_qd_54', 'cn_qd_210', 'cn_qd_312'],
	'tc-pokemon-cn_qd-06': ['cn_qd_05', 'cn_qd_55', 'cn_qd_211', 'cn_qd_313'],
	'tc-pokemon-cn_qd-07': ['cn_qd_06', 'cn_qd_56', 'cn_qd_212', 'cn_qd_314'],
	'tc-pokemon-cn_qd-08': ['cn_qd_07', 'cn_qd_57', 'cn_qd_213', 'cn_qd_315'],
	'tc-pokemon-cn_qd-09': ['cn_qd_08', 'cn_qd_58', 'cn_qd_214', 'cn_qd_316'],
	'tc-pokemon-cn_qd-10': ['cn_qd_09', 'cn_qd_59', 'cn_qd_215', 'cn_qd_317'],
	'tc-pokemon-cn_qd-11': ['cn_qd_10', 'cn_qd_60', 'cn_qd_216', 'cn_qd_318'],
	'tc-pokemon-cn_qd-12': ['cn_qd_11', 'cn_qd_61', 'cn_qd_217', 'cn_qd_319'],
	'tc-pokemon-cn_qd-13': ['cn_qd_12', 'cn_qd_62', 'cn_qd_218', 'cn_qd_320'],
	'tc-pokemon-cn_qd-14': ['cn_qd_13', 'cn_qd_63', 'cn_qd_219', 'cn_qd_321'],
	'tc-pokemon-cn_qd-15': ['cn_qd_14', 'cn_qd_64', 'cn_qd_220', 'cn_qd_322'],
	'tc-pokemon-cn_qd-16': ['cn_qd_15', 'cn_qd_65', 'cn_qd_221', 'cn_qd_323'],
	'tc-pokemon-cn_qd-17': ['cn_qd_16', 'cn_qd_66', 'cn_qd_222', 'cn_qd_324'],
	'tc-pokemon-cn_qd-18': ['cn_qd_17', 'cn_qd_67', 'cn_qd_223', 'cn_qd_325'],
	'tc-pokemon-cn_qd-19': ['cn_qd_18', 'cn_qd_68', 'cn_qd_224', 'cn_qd_326'],
	'tc-pokemon-cn_qd-20': ['cn_qd_19', 'cn_qd_69', 'cn_qd_225', 'cn_qd_327'],
	'tc-pokemon-cn_qd-21': ['cn_qd_20', 'cn_qd_70', 'cn_qd_226', 'cn_qd_328'],
	'tc-pokemon-cn_qd-22': ['cn_qd_21', 'cn_qd_71', 'cn_qd_227', 'cn_qd_329'],
	'tc-pokemon-cn_qd-23': ['cn_qd_22', 'cn_qd_72', 'cn_qd_228', 'cn_qd_330'],
	'tc-pokemon-cn_qd-24': ['cn_qd_23', 'cn_qd_73', 'cn_qd_229', 'cn_qd_331'],
	'tc-pokemon-cn_qd-25': ['cn_qd_24', 'cn_qd_74', 'cn_qd_230', 'cn_qd_332'],
	'tc-pokemon-cn_qd-26': ['cn_qd_25', 'cn_qd_75', 'cn_qd_231', 'cn_qd_333'],
	'tc-pokemon-cn_qd-27': ['cn_qd_26', 'cn_qd_76', 'cn_qd_232', 'cn_qd_334'],
	'tc-pokemon-cn_qd-28': ['cn_qd_27', 'cn_qd_77', 'cn_qd_233', 'cn_qd_335'],
	'tc-pokemon-cn_qd-29': ['cn_qd_28', 'cn_qd_78', 'cn_qd_234', 'cn_qd_336'],
	'tc-pokemon-cn_qd-30': ['cn_qd_29', 'cn_qd_79', 'cn_qd_235', 'cn_qd_337'],
	'tc-pokemon-cn_qd-31': ['cn_qd_30', 'cn_qd_80', 'cn_qd_236', 'cn_qd_338'],
	'tc-pokemon-cn_qd-32': ['cn_qd_31', 'cn_qd_81', 'cn_qd_237', 'cn_qd_339'],
	'tc-pokemon-cn_qd-33': ['cn_qd_32', 'cn_qd_82', 'cn_qd_238', 'cn_qd_340'],
	'tc-pokemon-cn_qd-34': ['cn_qd_33', 'cn_qd_83', 'cn_qd_239', 'cn_qd_341'],
	'tc-pokemon-cn_qd-35': ['cn_qd_34', 'cn_qd_84', 'cn_qd_240', 'cn_qd_342'],
	'tc-pokemon-cn_qd-36': ['cn_qd_35', 'cn_qd_85', 'cn_qd_241', 'cn_qd_343'],
	'tc-pokemon-cn_qd-37': ['cn_qd_36', 'cn_qd_86', 'cn_qd_242', 'cn_qd_344'],
	'tc-pokemon-cn_qd-38': ['cn_qd_37', 'cn_qd_87', 'cn_qd_243', 'cn_qd_345'],
	'tc-pokemon-cn_qd-39': ['cn_qd_38', 'cn_qd_88', 'cn_qd_244', 'cn_qd_346'],
	'tc-pokemon-cn_qd-40': ['cn_qd_39', 'cn_qd_89', 'cn_qd_245', 'cn_qd_347'],
	'tc-pokemon-cn_qd-41': ['cn_qd_40', 'cn_qd_90', 'cn_qd_246', 'cn_qd_348'],
	'tc-pokemon-cn_qd-42': ['cn_qd_41', 'cn_qd_91', 'cn_qd_247', 'cn_qd_349'],
	'tc-pokemon-cn_qd-43': ['cn_qd_42', 'cn_qd_92', 'cn_qd_248', 'cn_qd_350'],
	'tc-pokemon-cn_qd-44': ['cn_qd_43', 'cn_qd_93', 'cn_qd_249', 'cn_qd_351'],
	'tc-pokemon-cn_qd-45': ['cn_qd_44', 'cn_qd_94', 'cn_qd_250', 'cn_qd_352'],
	'tc-pokemon-cn_qd-46': ['cn_qd_45', 'cn_qd_95', 'cn_qd_251', 'cn_qd_353'],
	'tc-pokemon-cn_qd-47': ['cn_qd_46', 'cn_qd_96', 'cn_qd_252', 'cn_qd_354'],
	'tc-pokemon-cn_qd-48': ['cn_qd_47', 'cn_qd_97', 'cn_qd_253', 'cn_qd_355'],
	'tc-pokemon-cn_qd-49': ['cn_qd_48', 'cn_qd_98', 'cn_qd_254', 'cn_qd_356'],
	'tc-pokemon-cn_qd-50': ['cn_qd_49', 'cn_qd_99', 'cn_qd_255', 'cn_qd_357'],
	'tc-pokemon-cn_qd-51': ['cn_qd_50', 'cn_qd_100', 'cn_qd_256', 'cn_qd_358'],
	'tc-pokemon-cn_qd-52': ['cn_qd_101', 'cn_qd_102', 'cn_qd_257', 'cn_qd_359'],
	'tc-pokemon-cn_qd-53': ['cn_qd_103', 'cn_qd_104', 'cn_qd_258', 'cn_qd_360'],
	'tc-pokemon-cn_qd-54': ['cn_qd_105', 'cn_qd_106', 'cn_qd_259', 'cn_qd_361'],
	'tc-pokemon-cn_qd-55': ['cn_qd_107', 'cn_qd_108', 'cn_qd_260', 'cn_qd_362'],
	'tc-pokemon-cn_qd-56': ['cn_qd_109', 'cn_qd_110', 'cn_qd_261', 'cn_qd_363'],
	'tc-pokemon-cn_qd-57': ['cn_qd_111', 'cn_qd_112', 'cn_qd_262', 'cn_qd_364'],
	'tc-pokemon-cn_qd-58': ['cn_qd_113', 'cn_qd_114', 'cn_qd_263', 'cn_qd_365'],
	'tc-pokemon-cn_qd-59': ['cn_qd_115', 'cn_qd_116', 'cn_qd_264', 'cn_qd_366'],
	'tc-pokemon-cn_qd-60': ['cn_qd_117', 'cn_qd_118', 'cn_qd_265', 'cn_qd_367'],
	'tc-pokemon-cn_qd-61': ['cn_qd_119', 'cn_qd_120', 'cn_qd_266', 'cn_qd_368'],
	'tc-pokemon-cn_qd-62': ['cn_qd_121', 'cn_qd_122', 'cn_qd_267', 'cn_qd_369'],
	'tc-pokemon-cn_qd-63': ['cn_qd_123', 'cn_qd_124', 'cn_qd_268', 'cn_qd_370'],
	'tc-pokemon-cn_qd-64': ['cn_qd_125', 'cn_qd_126', 'cn_qd_269', 'cn_qd_371'],
	'tc-pokemon-cn_qd-65': ['cn_qd_127', 'cn_qd_128', 'cn_qd_270', 'cn_qd_372'],
	'tc-pokemon-cn_qd-66': ['cn_qd_129', 'cn_qd_130', 'cn_qd_271', 'cn_qd_373'],
	'tc-pokemon-cn_qd-67': ['cn_qd_131', 'cn_qd_132', 'cn_qd_272', 'cn_qd_374'],
	'tc-pokemon-cn_qd-68': ['cn_qd_133', 'cn_qd_134', 'cn_qd_273', 'cn_qd_375'],
	'tc-pokemon-cn_qd-69': ['cn_qd_135', 'cn_qd_136', 'cn_qd_274', 'cn_qd_376'],
	'tc-pokemon-cn_qd-70': ['cn_qd_137', 'cn_qd_138', 'cn_qd_275'],
	'tc-pokemon-cn_qd-71': ['cn_qd_139', 'cn_qd_140', 'cn_qd_276'],
	'tc-pokemon-cn_qd-72': ['cn_qd_141', 'cn_qd_142', 'cn_qd_277'],
	'tc-pokemon-cn_qd-73': ['cn_qd_143', 'cn_qd_144', 'cn_qd_278'],
	'tc-pokemon-cn_qd-74': ['cn_qd_145', 'cn_qd_146', 'cn_qd_279'],
	'tc-pokemon-cn_qd-75': ['cn_qd_147', 'cn_qd_148', 'cn_qd_280'],
	'tc-pokemon-cn_qd-76': ['cn_qd_149', 'cn_qd_150', 'cn_qd_281'],
	'tc-pokemon-cn_qd-77': ['cn_qd_151', 'cn_qd_152', 'cn_qd_282'],
	'tc-pokemon-cn_qd-78': ['cn_qd_153', 'cn_qd_154', 'cn_qd_283'],
	'tc-pokemon-cn_qd-79': ['cn_qd_155', 'cn_qd_156', 'cn_qd_284'],
	'tc-pokemon-cn_qd-80': ['cn_qd_157', 'cn_qd_158', 'cn_qd_285'],
	'tc-pokemon-cn_qd-81': ['cn_qd_159', 'cn_qd_160', 'cn_qd_286'],
	'tc-pokemon-cn_qd-82': ['cn_qd_161', 'cn_qd_162', 'cn_qd_287'],
	'tc-pokemon-cn_qd-83': ['cn_qd_163', 'cn_qd_164', 'cn_qd_288'],
	'tc-pokemon-cn_qd-84': ['cn_qd_165', 'cn_qd_166', 'cn_qd_289'],
	'tc-pokemon-cn_qd-85': ['cn_qd_167', 'cn_qd_168', 'cn_qd_290'],
	'tc-pokemon-cn_qd-86': ['cn_qd_169', 'cn_qd_170', 'cn_qd_291'],
	'tc-pokemon-cn_qd-87': ['cn_qd_171', 'cn_qd_172', 'cn_qd_292'],
	'tc-pokemon-cn_qd-88': ['cn_qd_173', 'cn_qd_174', 'cn_qd_293'],
	'tc-pokemon-cn_qd-89': ['cn_qd_175', 'cn_qd_176', 'cn_qd_294'],
	'tc-pokemon-cn_qd-90': ['cn_qd_177', 'cn_qd_178', 'cn_qd_295'],
	'tc-pokemon-cn_qd-91': ['cn_qd_179', 'cn_qd_180', 'cn_qd_296'],
	'tc-pokemon-cn_qd-92': ['cn_qd_181', 'cn_qd_182', 'cn_qd_297'],
	'tc-pokemon-cn_qd-93': ['cn_qd_183', 'cn_qd_184', 'cn_qd_298'],
	'tc-pokemon-cn_qd-94': ['cn_qd_185', 'cn_qd_186', 'cn_qd_299'],
	'tc-pokemon-cn_qd-95': ['cn_qd_187', 'cn_qd_188', 'cn_qd_300'],
	'tc-pokemon-cn_qd-96': ['cn_qd_189', 'cn_qd_190', 'cn_qd_301'],
	'tc-pokemon-cn_qd-97': ['cn_qd_191', 'cn_qd_192', 'cn_qd_302'],
	'tc-pokemon-cn_qd-98': ['cn_qd_193', 'cn_qd_194', 'cn_qd_303'],
	'tc-pokemon-cn_qd-99': ['cn_qd_195', 'cn_qd_196', 'cn_qd_304'],
	'tc-pokemon-cn_qd-100': ['cn_qd_197', 'cn_qd_198', 'cn_qd_305'],
	'tc-pokemon-cn_qd-101': ['cn_qd_199', 'cn_qd_200', 'cn_qd_306'],
	'tc-pokemon-cn_qd-102': ['cn_qd_201', 'cn_qd_202', 'cn_qd_307'],
	'tc-pokemon-cn_qd-103': ['cn_qd_203', 'cn_qd_204', 'cn_qd_308'],
	'tc-pokemon-cn_qd-104': ['cn_qd_205', 'cn_qd_206'],
	'tc-pokemon-cn_qd-105': [],
	'tc-pokemon-cn_qd-106': [],
	'tc-pokemon-cn_qd-107': [],
	'tc-pokemon-cn_qd-108': [],
	'tc-pokemon-cn_qd-109': [],
	'tc-pokemon-cn_qd-110': [],
	'tc-pokemon-cn_qd-111': [],
	'tc-pokemon-cn_qd-112': [],

	'xy-pokemon-cn-01': ['xy_01', 'xy_09'],
	'xy-pokemon-cn-02': ['xy_02', 'xy_10'],
	'xy-pokemon-cn-03': ['xy_03', 'xy_11'],
	'xy-pokemon-cn-04': ['xy_04', 'xy_12'],
	'xy-pokemon-cn-05': ['xy_05', 'xy_13'],
	'xy-pokemon-cn-06': ['xy_06', 'xy_14'],
	'xy-pokemon-cn-07': ['xy_07', 'xy_15'],
	'xy-pokemon-cn-08': ['xy_08', 'xy_16'],

	'tc-pokemon-kr-01': ['kr_01'],
	'tc-pokemon-kr-02': ['kr_02'],
	'tc-pokemon-kr-03': ['kr_03'],
	'tc-pokemon-kr-04': [],
	'tc-pokemon-kr-05': [],
	'tc-pokemon-kr-06': [],
	'tc-pokemon-kr-07': [],
	'tc-pokemon-kr-08': [],
	'tc-pokemon-kr-09': [],
	'tc-pokemon-kr-10': [],

	'tc-pokemon-en-01': ["en_01"],
	'tc-pokemon-en-02': ["en_02"],
	'tc-pokemon-en-03': ["en_03"],
	'tc-pokemon-en-04': ["en_04"],
	'tc-pokemon-en-05': ["en_05"],
	'tc-pokemon-en-06': ["en_06"],
	'tc-pokemon-en-07': ["en_07"],
	'tc-pokemon-en-08': ["en_08"],
	'tc-pokemon-en-09': ["en_09"],
	'tc-pokemon-en-10': ["en_10"],
	'tc-pokemon-en-11': ["en_11"],
	'tc-pokemon-en-12': ["en_12"],
	'tc-pokemon-en-13': ["en_13"],
	'tc-pokemon-en-14': ["en_14"],
	'tc-pokemon-en-15': ["en_15"],
	'tc-pokemon-en-16': ["en_16"],
	'tc-pokemon-en-17': ["en_17"],
	'tc-pokemon-en-18': ["en_18"],
	'tc-pokemon-en-19': ["en_19"],

	'ks-pokemon-tw-01': ['tw_01', 'tw_11'],
	'ks-pokemon-tw-02': ['tw_02', 'tw_12'],
	'ks-pokemon-tw-03': ['tw_03', 'tw_13'],
	'ks-pokemon-tw-04': ['tw_04', 'tw_14'],
	'ks-pokemon-tw-05': ['tw_05', 'tw_15'],
	'ks-pokemon-tw-06': ['tw_06', 'tw_16'],
	'ks-pokemon-tw-07': ['tw_07', 'tw_17'],
	'ks-pokemon-tw-08': ['tw_08', 'tw_18'],
	'ks-pokemon-tw-09': ['tw_09'],
	'ks-pokemon-tw-10': ['tw_10'],
	'ks-pokemon-tw-11': [],
	'ks-pokemon-tw-12': [],
}

SVN_HOST = "192.168.1.125"
GIT_HOST = "192.168.1.250"
SVN_LOCAL_PORT = 3690
SVN_REMOTE_PORT = 3690
GIT_LOCAL_PORT = 443
GIT_REMOTE_PORT = 3000

def get_deploy_path(c):
	ret = c.run('ls -d /mnt/deploy*').stdout.strip()
	if len(str(ret).split()) != 1:
		abort("deploy dictionary can not be determinately!")
	return ret

def get_config_csv_name(c):
	if 'xy' in c.original_host:
		return 'cn_config_csv.py'
	return '%s_config_csv.py' % c.original_host.split('-')[-2].split('_')[0]

def get_msgpack_csv_name(c):
	return '%s.config_csv.msgpack' % c.original_host.split('-')[-2].split('_')[0]

def get_deploy_name(x, s):
	# (cn_qd_01_merge, game_server) -> cn_01_gamemerge_server
	if x.find('merge') >= 0:
		v = x.split('_')
		x = '_'.join(v[:-1])
		v = s.split('_')
		return '%s_%smerge_%s' % (x, v[0], v[1])
	return '%s_%s' % (x, s)

class parallel(object):
	def __init__(self, hosts=None, host=None, parallel=None):
		self.hosts = hosts
		if host:
			self.hosts = [host]
		self._parallel = parallel

	def __call__(self, func):
		@wraps(func)
		def _warp():
			results = {}
			if self._parallel:
				n = self._parallel
			else:
				n = len(self.hosts)
			steps = [self.hosts[i: i+n] for i in xrange(0, len(self.hosts), n)]
			for hosts in steps:
				print 'hosts', hosts
				group = MyThreadingGroup(*hosts, config=config)
				# group = MyThreadingGroup(*hosts, config=config, gateway=Connection('ks-pokemon-tw-gm', config=config))
				result = group.execute(func)
				results.update(result)
			return results
		return _warp

# @task(hosts=roledefs['allgame'])
@parallel(hosts=roledefs['allgame'], parallel=50)
# @parallel(hosts=roledefs['twgame'])
# @parallel(hosts=roledefs['engame'])
# @parallel(hosts=['ks-pokemon-tw-gm'])
def all_svn_up(c):
	def _svn_up():
		with c.forward_remote(local_port=SVN_LOCAL_PORT, local_host=SVN_HOST, remote_port=SVN_REMOTE_PORT):
			print c.original_host
			c.run('svn cleanup')

			c.run('sed -i "s/# store-passwords = no/store-passwords = yes/g" ~/.subversion/servers')
			c.run('sed -i "s/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g" ~/.subversion/servers')
			# c.run('svn revert bin/* cn.config_csv.msgpack cn_config_csv.py')

			ret = c.run('svn up --username test --password 123456')
			# ret = c.run('svn up bin cn.config_csv.msgpack --username test --password 123456')
			if ret.exited != 0:
				if ret.stdout.find('E205011') < 0:
					# TODO:
					pass

			c.run('chmod +x bin/*')
			return c.run('svn info').stdout

	with c.cd('/mnt/release'):
		try:
			_svn_up()
		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = c.run('lsof -i:3690|grep sshd|awk \'{print $2}\'').stdout
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				if len(ret) > 0:
					c.run('kill -9 %d' % int(ret))
				_svn_up()

@parallel(hosts=roledefs['allgame'], parallel=50)
# @parallel(hosts=roledefs['qdgame'])
def all_csv_svn_up(c):
	def _csv_svn_up():
		with c.forward_remote(local_port=SVN_LOCAL_PORT, local_host=SVN_HOST, remote_port=SVN_REMOTE_PORT):
			c.run('svn cleanup')

			c.run('sed -i "s/# store-passwords = no/store-passwords = yes/g" ~/.subversion/servers')
			c.run('sed -i "s/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g" ~/.subversion/servers')

			filename = get_config_csv_name(c)
			# filename = 'kr_config_csv.py'
			# filename = 'cn.config_csv.msgpack'

			c.run('svn revert %s --username test --password 123456' % filename)
			ret = c.run('svn up %s --username test --password 123456' % filename)
			#ret = c.run('svn up')
			if ret.exited != 0:
				if ret.stdout.find('E205011') < 0:
					# TODO:
					pass

			return c.run('svn info %s' % filename).stdout

	with c.cd('/mnt/release'):
		try:
			_csv_svn_up()
		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = c.run('lsof -i:3690|grep sshd|awk \'{print $2}\'').stdout
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				if len(ret) > 0:
					c.run('kill -9 %d' % int(ret))
				_csv_svn_up()

@parallel(hosts=roledefs['allgame'], parallel=50)
# @parallel(hosts=roledefs['all'])
# @parallel(hosts=roledefs['twgame'])
# @parallel(hosts=roledefs['engame'])
def all_game_up(c):
	def _game_up():
		with c.forward_remote(local_port=GIT_LOCAL_PORT, local_host=GIT_HOST, remote_port=GIT_REMOTE_PORT):
			c.run('git pull origin master')

	with c.cd('/mnt/release/src'):
		try:
			_game_up()
		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = c.run('lsof -i:3000|grep sshd|awk \'{print $2}\'').stdout
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				if len(ret) > 0:
					c.run('kill -9 %d' % int(ret))
				_game_up()

@parallel(hosts=roledefs['allgame'])
# @parallel(hosts=roledefs['other'])
# @parallel(hosts=roledefs['twgame'])
def close_all_servers(c):
	with c.cd(get_deploy_path(c)):
		if c.original_host not in ServerIDMap:
			return
		serverIDs = ServerIDMap[c.original_host]
		for s in ServerNameList:
			deployNameL = [get_deploy_name(x, s) for x in serverIDs]
			print deployNameL
			for dpy in deployNameL:
				c.run('supervisorctl stop %s' % dpy)

			for dpy in deployNameL:
				i = 0
				while True:
					ret = c.run('supervisorctl status %s' % dpy).stdout.strip()
					if ret.find('STOPPED') > 0 or ret.find('EXITED') > 0:
						break
					print dpy, 'stop waiting', i
					time.sleep(random.randint(1, 5))
					i += 1
			time.sleep(random.randint(1, 5))

def list_split(items, n):
	return [items[i:i+n] for i in range(0, len(items), n)]

@parallel(hosts=roledefs['allgame'], parallel=80)
# @parallel(host='ks-pokemon-tw-02')
# @parallel(hosts=roledefs['twgame'])
def start_all_servers(c):
	with c.cd(get_deploy_path(c)):
		if c.original_host not in ServerIDMap:
			return
		serverIDs = ServerIDMap[c.original_host]
		steps = list_split(serverIDs, 8)
		for serverIDs in steps:
			for s in reversed(ServerNameList):
				waitIDs = []
				for x in serverIDs:
					dpy = get_deploy_name(x, s)
					ret = c.run('supervisorctl status %s' % dpy).stdout.strip()
					if ret.find('RUNNING') < 0:
						waitIDs.append(x)
						c.run('supervisorctl start %s' % dpy)
						time.sleep(random.randint(1, 5))

				for x in waitIDs:
					dpy = get_deploy_name(x, s)
					with c.cd('childlog'):
						i = 0
						while True:
							if s == 'game_server':
								ret = c.run('cat {dpy}/`date "+%Y-%m-%d"`.log|grep -E "(Start OK|End of file)"'.format(dpy=dpy)).stdout.strip()
							else:
								ret = c.run('cat {dpy}*.log|grep "start ok"|grep "`date "+%y%m%d"`"'.format(dpy=dpy)).stdout.strip()
							if ret.find('Start OK') > 0 or ret.find('start ok') > 0:
								break
							if ret.find('End of file') > 0:
								with c.cd(get_deploy_path(c)):
									if c.run('supervisorctl status %s' % dpy).stdout.strip().find('RUNNING') < 0:
										c.run('supervisorctl start %s' % dpy)
							print dpy, 'start waiting', i
							time.sleep(random.randint(1, 5))
							i += 1
				# time.sleep(random.randint(1, 5))

def _start_all_servers():
	startMachineTotal = roledefs['allgame'] # 启动的机器
	startCountMult = 20 # 同时启动的个数

	startMachines = []

	for item in startMachineTotal:
		startMachines.append(item)
		if len(startMachines) == startCountMult:
			print 'start', startMachines
			p = parallel(startMachines)
			p.__call__(_start_all_servers)()
			print 'finish', startMachines
			startMachines = []

	if startMachines:
		print 'start', startMachines
		p = parallel(startMachines)
		p.__call__(_start_all_servers)()
		print 'finish', startMachines


@parallel(hosts=roledefs['allgame'])
def close_cross(c):
	with c.cd(get_deploy_path(c)):
		if c.original_host not in CrossIDMap:
			return
		serverIDs = CrossIDMap[c.original_host]
		for s in ['cross_server', 'crossdb_server']:
			deployNameL = [get_deploy_name(x, s) for x in serverIDs]
			# print deployNameL
			for dpy in deployNameL:
				c.run('supervisorctl stop %s' % dpy)

			for dpy in deployNameL:
				i = 0
				while True:
					ret = c.run('supervisorctl status %s' % dpy).stdout.strip()
					if ret.find('STOPPED') > 0 or ret.find('EXITED') > 0:
						break
					print dpy, 'stop waiting', i
					time.sleep(1)
					i += 1

@parallel(hosts=roledefs['allgame'])
# @parallel(hosts=roledefs['other'])
def start_cross(c):
	with c.cd(get_deploy_path(c)):
		if c.original_host not in CrossIDMap:
			return
		serverIDs = CrossIDMap[c.original_host]
		for s in ['crossdb_server', 'cross_server']:
			waitIDs = []
			for x in serverIDs:
				dpy = get_deploy_name(x, s)
				ret = c.run('supervisorctl status %s' % dpy).stdout.strip()
				if ret.find('RUNNING') < 0:
					waitIDs.append(x)
					c.run('supervisorctl start %s' % dpy)

			for x in waitIDs:
				dpy = get_deploy_name(x, s)
				with c.cd('childlog'):
					i = 0
					while True:
						ret = c.run('cat {dpy}*.log|grep "start ok"|grep "`date "+%y%m%d"`"'.format(dpy=dpy)).stdout.strip()
						if ret.find('Start OK') > 0 or ret.find('start ok') > 0:
							break
						print dpy, 'start waiting', i
						time.sleep(1)
						i += 1


@parallel(hosts=roledefs['allgame'])
# @parallel(hosts=roledefs['other'])
def restart_cross(c):
	with c.cd(get_deploy_path(c)):
		if c.original_host not in CrossIDMap:
			return
		serverIDs = CrossIDMap[c.original_host]
		for x in serverIDs:
			dpy = '%s_cross_server' % x
			c.run('supervisorctl stop %s' % dpy)
			# time.sleep(random.randint(1, 5))
			c.run('supervisorctl start %s' % dpy)

@parallel(hosts=roledefs['allgame'])
# @parallel(hosts=roledefs['twgame'])
# @parallel(hosts=roledefs['all'])
# @parallel(hosts=roledefs['other'])
def _system_all_servers(c):
	ps = c.run('ps aux|grep -E "(/mnt/deploy|/usr/bin/python.*?py)"|sort -k 6 -n -r').stdout.strip()
	free = c.run('free -m').stdout.strip()
	uptime = c.run('uptime').stdout.strip()
	processor = c.run('cat /proc/cpuinfo |grep "processor"|wc -l').stdout.strip()
	svn = ''
	svn_config = ''
	svn_msgpack = ''
	with c.cd('/mnt/release'):
		svn = c.run('svn info').stdout.strip()
		svn_config = c.run('svn info %s' % get_config_csv_name(c)).stdout.strip()
		#svn_config = c.run('svn info %s' % 'cn.config_csv.msgpack').stdout.strip()
	with c.cd('/mnt/release'):
		svn = c.run('svn info').stdout.strip()
		svn_msgpack = c.run('svn info %s' % get_msgpack_csv_name(c)).stdout.strip()
	git = ''
	with c.cd('/mnt/release/src'):
		git = c.run('git log --pretty=format:"%h" -1').stdout.strip()

	svn_agent_csv = ''
	with c.cd('/mnt/release/anti_cheat/game_config'):
		svn_agent_csv = c.run('svn info').stdout.strip()
	svn_agent_model = ''
	with c.cd('/mnt/release/anti_cheat/game_scripts/application/src/battle'):
		svn_agent_model = c.run('svn info').stdout.strip()
	git_agent = ''
	with c.cd('/mnt/release/anti_cheat/game_scripts/framework'):
		git_agent = c.run('git log --pretty=format:"%h" -1').stdout.strip()
	ls_agent_csv = ''
	with c.cd('/mnt/release/anti_cheat/game_scripts/config'):
		ls_agent_csv = c.run('ls -l').stdout.strip()
	lang_agent = ''
	with c.cd('/mnt/release/anti_cheat/game_scripts'):
		lang_agent = c.run('cat anti_main.lua|grep "LOCAL_LANGUAGE ="').stdout.strip()

	# net_est = c.run('''netstat -ntal|grep ESTABLISHED|grep -E ":[12][0-9]888"|awk '{a[$4]+=1}END{for (i in a) print(i, a[i])}'|sort''').stdout.strip()
	# net_wait = c.run('''netstat -ntal|grep -E "(TIME_WAIT|CLOSING)"|grep -E ":[12][0-9]888"|awk '{a[$4]+=1}END{for (i in a) print(i, a[i])}'|sort''').stdout.strip()

	net_est = c.run('''netstat -ntal|grep ESTABLISHED|grep -E ":[0-9][0-9]888"|wc -l''').stdout.strip()
	net_wait = c.run('''netstat -ntal|grep -E "(TIME_WAIT|CLOSING)"|grep -E ":[0-9][0-9]888"|wc -l''').stdout.strip()

	return (ps, free, uptime, processor, svn, svn_config, svn_msgpack, git, svn_agent_csv, svn_agent_model, git_agent, ls_agent_csv, lang_agent, net_est, net_wait)

def system_all_servers():
	result = _system_all_servers()

	infos = []
	warns = []
	times = []
	agentinfos = []
	netinfos = []

	for c in sorted(result.keys(), key=lambda x:(x.original_host.split('-')[:-1], int(x.original_host.split('-')[-1]))):
		k = c.original_host
		print '-' * 20
		print k, ':'
		ps, free, uptime, processor, svn, svn_config, svn_msgpack, git, svn_agent_csv, svn_agent_model, git_agent, ls_agent_csv, lang_agent, net_est, net_wait = result[c]
		gameservers = 0
		pvpservers = 0
		storageservers = 0
		agents = 0
		crossservers = 0

		lines = ps.split('\n')
		for line in lines:
			lst = line.split()
			big = False
			if line.find('game_server') >= 0:
				gameservers += 1
				times.append((lst[-1], 'TIME %s' % lst[-4], 'CPU %s%%' % lst[2], 'MEM %s%%' % lst[3], 'RSS %.2f GB' % (float(lst[5]) / 1024 / 1024) ))
			if line.find('-config=pvp.') >= 0 or line.find('-config=pvpmerge.') >= 0:
				pvpservers += 1
				big = int(lst[5]) > 5 * 1024 * 1024
			if line.find('-config=storage.') >= 0 or line.find('-config=storagemerge.') >= 0 or line.find('-config=crossdb.') >= 0:
				storageservers += 1
			if line.find('anti_cheat_server') >=0:
				agents += 1
				big = int(lst[5]) > 1024 * 1024
			if line.find('-config=cross.') >= 0:
				crossservers += 1
			big = big or int(lst[5]) > 8 * 1024 * 1024
			if big:
				warns.append(('MEM TOO BIG', '%.2fG' % (float(lst[5]) / 1024 / 1024), k, lst[-2], lst[-1]))

		lines = free.split('\n')
		lst = lines[2].split()
		swap = lines[3].split()
		used_mem, free_mem = 'used %.2fG' % (float(lst[2]) / 1024), 'free %.2fG' % (float(lst[3]) / 1024)
		used_swap, free_swap = 'used_swap %.2fG' % (float(swap[2]) / 1024), 'free_swap %.2fG' % (float(swap[3]) / 1024)
		if float(swap[2]) + float(swap[3]) < 0.1:
			used_swap = free_swap = None
		low = False
		low = int(lst[3]) < 30 * 1024
		if low and False:
			warns.append(('FREE MEM TOO LOW', k, used_mem, free_mem))

		lst = uptime.split()

		lstsvn = svn.split('\n')
		for svnline in lstsvn:
			if svnline.find('Revision:') >= 0:
				svnline = svnline[10:].strip()
				break

		lstsvn = svn_config.split('\n')
		for svnconfigline in lstsvn:
			if svnconfigline.find('Revision:') >= 0:
				svnconfigline = svnconfigline[10:].strip()
				break

		lstsvn = svn_msgpack.split('\n')
                for svnmsgpackline in lstsvn:
                        if svnmsgpackline.find('Revision:') >= 0:
                                svnmsgpackline = svnmsgpackline[10:].strip()
                                break

		lstgit = git

		if agents > 0:
			lstsvn = svn_agent_csv.split('\n')
			for svnagentline1 in lstsvn:
				if svnagentline1.find('Revision:') >= 0:
					break

			lstsvn = svn_agent_model.split('\n')
			for svnagentline2 in lstsvn:
				if svnagentline2.find('Revision:') >= 0:
					break

			lstsvn = ls_agent_csv.split('\n')
			for lsagentline in lstsvn:
				if lsagentline.find('csv.lua') >= 0:
					lsagentline = ' '.join(lsagentline.split()[-4:-1])
					break

			lstsvn = lang_agent.split("'")
			langagent = lstsvn[-2]

			agentinfos.append(('agent-%s' % k, 'csv %s' % svnagentline1.strip(), 'model %s' % svnagentline2.strip(), 'csv2lua %s' % lsagentline.strip(), 'git %s' % git_agent.strip(), 'lang %s' % langagent.strip()))

		ns = len(ServerIDMap.get(k, []))
		nc = len(CrossIDMap.get(k, []))
		flag = ""
		if ns != gameservers or ns != pvpservers:
			flag = "!"
		if nc != crossservers or (ns + nc) != storageservers:
			flag = "!"

		swap_mem = ""
		if free_swap is not None:
			swap_mem = "%s %s" % (used_swap, free_swap)
		filename = get_config_csv_name(c)
		msgpackname = get_msgpack_csv_name(c)
		infos.append((k, '%s %s %s load %s %s %s' % (used_mem, free_mem, swap_mem, lst[-3], lst[-2], lst[-1]), '%s game %s/%d pvp %s cross %s/%d storage %s/%d release %s server %s %s %s %s %s' % (flag, gameservers, ns, pvpservers, crossservers, nc, storageservers, ns+nc, svnline, lstgit, filename, svnconfigline, msgpackname, svnmsgpackline)))

		netinfos.append((k, 'ESTABLISHED', net_est, 'TIME_WAIT', net_wait))

	print '\n'
	print '=' * 20
	for t in times:
		print '\t'.join(t)

	print '\n'
	print '='*20
	for info in agentinfos:
		print '\t'.join(info)

	print '\n'
	print '=' * 20
	for info in infos:
		print '\t'.join(info)

	print '\n'
	print '=' * 20
	for info in netinfos:
		print '\t'.join(info)

	print '\n'
	warns.sort(key=lambda t:t[0])
	for warn in warns:
		print 'WARNING:', '\t'.join(warn)

@parallel(hosts=roledefs['alllogin'])
def deploy_login_patch(c):
	def _patch_svn_up():
		with c.forward_remote(local_port=SVN_LOCAL_PORT, local_host=SVN_HOST, remote_port=SVN_REMOTE_PORT):
			c.run('svn up login/patch')

	with c.cd('/mnt/release'):
		try:
			_patch_svn_up()
		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = c.run('lsof -i:3690|grep sshd|awk \'{print $2}\'').stdout
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				if len(ret) > 0:
					c.run('kill -9 %d' % int(ret))
				_patch_svn_up()

@parallel(hosts=roledefs['allgame'], parallel=50)
# @parallel(hosts=roledefs['other'])
def build_all_agent(c):
	def _svn_up():
		with c.forward_remote(local_port=SVN_LOCAL_PORT, local_host=SVN_HOST, remote_port=SVN_REMOTE_PORT):
			c.run('svn cleanup')
			c.run('svn cleanup game_config')
			c.run('svn cleanup game_scripts')
			c.run('svn resolve --accept theirs-full game_scripts/*.lua')

			c.run('svn up --username test --password 123456').stdout.strip()

	def _git_pull():
		with c.forward_remote(local_port=GIT_LOCAL_PORT, local_host=GIT_HOST, remote_port=GIT_REMOTE_PORT):
			c.run('chmod +x deploy.sh')
			c.run('./deploy.sh release')

	with c.cd('/mnt/release/anti_cheat'):
		try:
			_svn_up()
		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = c.run('lsof -i:3690|grep sshd|awk \'{print $2}\'').stdout.strip()
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				if ret:
					c.run('kill -9 %d' % int(ret))
				_svn_up()

		try:
			_git_pull()
		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = c.run('lsof -i:3000|grep sshd|awk \'{print $2}\'').stdout.strip()
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				if ret:
					c.run('kill -9 %d' % int(ret))
				_git_pull()

	#return
	with c.cd(get_deploy_path(c)):
		names = c.run('supervisorctl status|grep "anti_cheat_server"|awk \'{print $1}\'').stdout.strip().split('\n')

		# stop
		for name in names:
			if name:
				c.run('supervisorctl stop %s' % name)

		with c.cd('/mnt/release/anti_cheat'):
			c.run('chmod +x agent')
			c.run('chmod +x csv2lua.sh')
			c.run('./csv2lua.sh')
		c.run('sleep 1')
		time.sleep(random.randint(1, 5))

		# start
		for name in names:
			if name:
				c.run('supervisorctl start %s' % name)

	with c.cd('/mnt/release/online_fight_forward'):
		with c.forward_remote(local_port=SVN_LOCAL_PORT, local_host=SVN_HOST, remote_port=SVN_REMOTE_PORT):
			c.run('svn up --username test --password 123456')

@parallel(hosts=roledefs['allgame'])
def restart_all_agent(c):
	with c.cd(get_deploy_path(c)):
		names = c.run('supervisorctl status|grep "anti_cheat_server"|awk \'{print $1}\'').stdout.strip().split('\n')

		# with c.forward_remote(local_port=SVN_LOCAL_PORT, local_host=SVN_HOST, remote_port=SVN_REMOTE_PORT):
		# 	with c.cd('/mnt/release/anti_cheat'):
		# 		c.run('svn up agent --username test --password 123456')

		# 	for name in names:
		# 		name = 'supervisord.dir/%s.ini' % name
		# 		c.run('svn up %s --username test --password 123456' % name)

		# stop
		for name in names:
			if name:
				c.run('supervisorctl stop %s' % name)
			# c.run('supervisorctl reread')
			# c.run('supervisorctl update %s' % name)

		# with c.cd('/mnt/release/anti_cheat'):
		# 	c.run('chmod +x agent')
		# 	c.run('chmod +x csv2lua.sh')
		# 	c.run('./csv2lua.sh')

		time.sleep(random.randint(1, 5))

		# start
		for name in names:
			if name:
				c.run('supervisorctl start %s' % name)

@parallel(hosts=roledefs['allgame'])
def restart_all_forward(c):
	with c.cd(get_deploy_path(c)):
		names = c.run('supervisorctl status|grep "online_fight_forward_server"|awk \'{print $1}\'').stdout.strip().split('\n')

		# stop
		for name in names:
			if name:
				c.run('supervisorctl stop %s' % name)
				# c.run('supervisorctl reread')
				# c.run('supervisorctl update %s' % name)

		time.sleep(random.randint(1, 5))

		# start
		for name in names:
			if name:
				c.run('supervisorctl start %s' % name)

# @parallel(host='tc-pokemon-cn_qd-88')
# @parallel(host='tc-pokemon-kr-01')
@parallel(hosts=roledefs['allcomment'])
def restart_comment_server(c):
	with c.cd(get_deploy_path(c)):
		lang = c.original_host.split('-')[-2].split('_')[0]
		if 'xy' in c.original_host:
			lang = 'xy'
		c.run('supervisorctl stop %s_01_comment_server' % lang)
		c.run('supervisorctl stop %s_01_commentdb_server' % lang)
		c.run('supervisorctl start %s_01_commentdb_server' % lang)
		c.run('supervisorctl start %s_01_comment_server' % lang)

@parallel(hosts=roledefs['allgame'], parallel=10)
def restart_all_server(c):
	SomeServerIDs = {}
	SomeServerNames = ['storage_server']

	with c.cd('/mnt/release'):
		c.run('chmod +x bin/*')

	with c.cd(get_deploy_path(c)):
		serverIDs = ServerIDMap[c.original_host]
		# someIDs = [x for x in serverIDs if x in SomeServerIDs]
		someIDs = serverIDs # 所有

		for s in SomeServerNames:
			for x in someIDs:
				dpy = get_deploy_name(x, s)
				time.sleep(1)
				c.run('supervisorctl stop %s' % dpy)
				c.run('supervisorctl start %s' % dpy)

		for s in reversed(SomeServerNames):
			for x in someIDs:
				dpy = get_deploy_name(x, s)
				with c.cd('childlog'):
					i = 0
					while True:
						if s == 'game_server':
							ret = c.run('cat {dpy}/`date "+%Y-%m-%d"`.log|grep "Start OK"'.format(dpy=dpy)).stdout.strip()
						else:
							ret = c.run('cat {dpy}*.log|grep "start ok"|grep "`date "+%y%m%d"`"'.format(dpy=dpy)).stdout.strip()
						if ret.find('Start OK') > 0 or ret.find('start ok') > 0:
							break
						print dpy, 'start waiting', i
						time.sleep(1)
						i += 1

# @parallel(host='tc-pokemon-cn-login')
# @parallel(host='xy-pokemon-cn-login')
# @parallel(host='tc-pokemon-kr-login')
# @parallel(host='tc-pokemon-en-login')
# @parallel(host='tc-pokemon-tw-login')
@parallel(hosts=roledefs['alllogin'])
def login_maintain(c):
	lang = c.original_host.split('-')[-2]
	with c.cd('/mnt/release/login/conf'):
		filename = ' %s/maintain.json' % lang
		ret = c.run('cat %s' % filename).stdout
		import json
		d = json.loads(ret)
		print c.original_host, d['maintain']
		# print ret

@parallel(host='tc-pokemon-cn-login')
# @parallel(host='xy-pokemon-cn-login')
# @parallel(host='tc-pokemon-en-login')
# @parallel(host='ks-pokemon-tw-login')
# @parallel(host='tc-pokemon-kr-login')
# @parallel(hosts=roledefs['alllogin'])
def login_maintain_start(c):
	lang = c.original_host.split('-')[-2]
	with c.cd('/mnt/release/login/conf'):
		filename = ' %s/maintain.json' % lang
		ret = c.run('cat %s' % filename).stdout
		import json
		d = json.loads(ret)
		d['maintain'] = False
		s = json.dumps(d, indent=2)
		c.run(''' echo '%s' > %s ''' % (s, filename))

# @parallel(hosts=roledefs['other'])
def restart_some_servers(c):
	SomeServerIDs = {'cn_qd_30', 'cn_qd_31', 'cn_qd_32', 'cn_qd_33', 'cn_qd_34', 'cn_qd_35', 'cn_qd_36', 'cn_qd_37', 'cn_qd_38', 'cn_qd_39', 'cn_qd_40', 'cn_qd_41', 'cn_qd_42', 'cn_qd_43', 'cn_qd_44', 'cn_qd_45', 'cn_qd_46', 'cn_qd_47', 'cn_qd_48', 'cn_qd_49'}
	# SomeServerIDs = set([])

	# SomeServerNames = ['game_server', 'pvp_server', 'storage_server']
	SomeServerNames = ['pvp_server']

	with c.cd(get_deploy_path(c)):
		serverIDs = ServerIDMap[c.original_host]
		# someIDs = [x for x in serverIDs if x in SomeServerIDs]
		someIDs = serverIDs # 所有

		for s in SomeServerNames:
			for x in someIDs:
				dpy = get_deploy_name(x, s)
				time.sleep(1)
				c.run('supervisorctl restart %s' % dpy)
			# for x in someIDs:
			# 	dpy = get_deploy_name(x, s)
			# 	i = 0
			# 	while True:
			# 		ret = c.run('supervisorctl status %s' % dpy).stdout.strip()
			# 		if ret.find('STOPPED') > 0 or ret.find('EXITED') > 0:
			# 			break
			# 		print dpy, 'stop waiting', i
			# 		time.sleep(1)
			# 		i += 1

		# for s in reversed(SomeServerNames):
		# 	for x in someIDs:
		# 		dpy = get_deploy_name(x, s)
		# 		time.sleep(random.randint(1, 10))
		# 		c.run('supervisorctl start %s' % dpy)
		# 	for x in someIDs:
		# 		dpy = get_deploy_name(x, s)
		# 		with c.cd('childlog'):
		# 			i = 0
		# 			while True:
		# 				if s == 'game_server':
		# 					ret = c.run('cat {dpy}/`date "+%Y-%m-%d"`.log|grep "Start OK"'.format(dpy=dpy)).stdout.strip()
		# 				else:
		# 					ret = c.run('cat {dpy}*.log|grep "start ok"|grep "`date "+%y%m%d"`"'.format(dpy=dpy)).stdout.strip()
		# 				if ret.find('Start OK') > 0 or ret.find('start ok') > 0:
		# 					break
		# 				print dpy, 'start waiting', i
		# 				time.sleep(1)
		# 				i += 1

# setopt no_nomatch
# cat cn_qd_{0*,10}_game_server/*.log|grep -E "(cost for frag_shop_buy|gain from card_decompose|gain from frag_shop_buy)" > 200413.log

@parallel(hosts=roledefs['allgame'])
# @parallel(hosts=roledefs['cngame'])
# @parallel(hosts=roledefs['other'])
# @parallel(hosts=['tc-pokemon-cn-06'])
def _in_log(c):
	result = {}
	with c.cd(get_deploy_path(c)):
	# 	serverIDs = ServerIDMap[c.original_host]
	# 	for sid in serverIDs:
	# 		with c.cd('childlog/%s_game_server' % sid):
	# 			ret = c.run(''' cat *.log|grep "/game/endless/"|grep "100150"''').stdout.strip()
	# 			result[sid] = ret

		#query = ''' supervisorctl status |grep "STOPPING" '''
		#result = c.run(query).stdout.strip()
		# if True:
		with c.cd('childlog'):
			#pass
#  			query = '''
# setopt no_nomatch
# cat *online_fight_forward*.log|grep "error"|sort|awk '{s[$1]=$0}END{for (i in s) print s[i];}'|sort
# '''
			# result = c.run(''' cat *online_fight_forward_server-stdout*|grep "Write stdin" ''').stdout.strip()
			# result = c.run(''' cat cn_*/2021-09-20.log|grep "cross_arena.py" ''').stdout.strip()
			# result = c.run(''' cat *pvp_server*.log|grep -E "210921.*weight sum zero"|sort|awk '{s[$1]=$0}END{for (i in s) print s[i];}'|sort ''').stdout.strip()
			# result = c.run(''' cat *pvp_server*.log|grep "200809.*checkPlayEnd"|sort|awk '{s[$1]=$0}END{for (i in s) print s[i];}'|sort ''').stdout.strip()
			# result = c.run(''' cat *cross_server*.log|grep "210920 .*crossarena.go"|sort|awk '{s[$1]=$0}END{for (i in s) print s[i];}'|sort ''').stdout.strip()
			# result = c.run(''' cat *pvp_server*.log|grep "200424.*craft.*agent play.*result error"|sort|awk '{s[$1]=$0}END{for (i in s) print s[i];}'|sort ''').stdout.strip()
			# result = c.run(''' cat *pvp_server*.log|grep "200425.*union_fight.go.* error"|sort|awk '{s[$1]=$0}END{for (i in s) print s[i];}'|sort ''').stdout.strip()
			# result = c.run(''' cat *pvp_server*.log|grep "200914 .*rank max"''').stdout.strip()
			# result = c.run(''' cat *pvp_server*.log.1 *pvp_server*.log|grep "200928 .*create robot"  ''').stdout.strip()
			# result = c.run(''' cat *storage_server*.log|grep "200505 .*:171.*response err" ''').stdout.strip()
			# result = c.run(''' cat *storage_server*.log|grep "200417 19.*MGO"''').stdout.strip()
			# result = c.run(''' cat *online_fight_forward_server*.log|grep ""|awk '{d[$2][$10]+=1} END{for(i in d) for (j in d[i])print i, j, d[i][j]}' ''').stdout.strip()
			# result = c.run(''' cat *_game_server/2021-09-21.log|grep -E "210921 10:.*/game/login"|awk '{d[$1]+=1} END{for (i in d) print i, d[i]}' ''').stdout.strip()
			# result = c.run(''' cat *_game_server/2020-07-*.log|grep "cost for yy_dinner,"|awk '{d[$1][$4]+=1} END{for (i in d) for (j in d[i]) print i, j, d[i][j]}' > 200804.log''').stdout.strip()
			# result = c.run(''' cat *_game_server/2021-06-03.log|grep "ArenaHuntingRecord" ''').stdout.strip()
			# result = c.run(''' cat *_game_server/2021-08-30.log | grep "CreateRobotCrossArenaRecordBulk" | grep timeout ''').stdout.strip()
			# result = c.run(''' cat cn_*_cross_server-*|grep 210830 |grep crossarena.go |grep "CrossArena.onStart" ''').stdout.strip()
			# result = c.run(''' cat *anti_cheat_server*.log|grep "200501 .*5eab7787c3d74465377a470d" ''').stdout.strip()
			# result = c.run(''' supervisorctl status|grep "uptime 0" ''').stdout.strip()
			result = c.run(''' cat *_game_server/2021-10-21.log *_game_server/2021-10-22.log|grep "gain from use_item, .*1271"|grep card ''').stdout.strip()
			# result = c.run(query.strip()).stdout.strip()

			# s = get_deploy_path(c)
			# c.get('%s/childlog/200804.log' % s, 'out/%s_200804.log' % c.original_host)
			# result = ''
			# lines = result.split('\n')
			# serverIDs = ServerIDMap[c.original_host]
			# if len(lines) != serverIDs:
			# 	print '!!!!', c.original_host
			# serverIDs = ServerIDMap[c.original_host]
			# s = get_deploy_path(c)
			# for sid in serverIDs:
				# ret = c.run('''nohup cat %s_game_server/*.log|grep -E "(REQ .*/game/card/nvalue/recast|cost for recast_cost)" > %s_card_recast.log &''' % (sid, sid)).stdout.strip()
				# print '%s_card_recast.log' % sid
				# c.get('%s/childlog/%s_card_recast.log' % (s, sid), '200721_card_recast/%s_card_recast.log' % sid)
				# result[sid] = '%s' % ret
				# result = 'ok'
			# result = c.run(''' tar czf 200721_card_recast.tar.gz *_card_recast.log ''').stdout.strip()
			# c.get('%s/childlog/200721_card_recast.tar.gz' % s, '200721_card_recast/%s_card_recast.tar.gz' % c.original_host)

			# v = []
			# for line in lines:
			# 	word = line.split()
			# 	serv = word[1]
			# 	roleID = word[9]
			# 	args = eval(''.join(word[15:]))
			# 	# print serv, roleID, args['gateID'], args['damage'], args['hpMax']
			# 	v.append('%s %s %s %s %s' % (serv, roleID, args['gateID'], args['damage'], args['hpMax']))
			# result = '\n'.join(v)
	return result

def in_log():
	try:
		result = _in_log()
	except Exception, e:
		print '!!!!!!', type(e)
		result = e.result

	with open('result.log', "wb") as fp:
		for c in sorted(result.keys(), key=lambda x: x.original_host):
			k = c.original_host
			ret = result[c]
			# if ret:
			print '-' * 20
			print k, ':'
			# fp.write('\n' + '-' * 20 + '\n')
			# fp.write(k + ':\n')
			ret = ret.encode('utf8')
			print ret
			fp.write(ret + '\n')
			if isinstance(ret, dict):
				for sid, s in ret.iteritems():
					s = s.strip()
					if not s:
						continue
					lst = s.split('\n')
					lst = ['%s %s' % (sid, x) for x in lst]
					print '\n'.join(lst)
					fp.write('\n'.join(lst) + '\n')


@parallel(hosts=['tc-pokemon-cn_qd-01'])
def get_shushu_log(c):
	name = '2020-10-21'
	with c.cd('/mnt/logbus_data/game.cn_qd.1'):
		c.run('tar czf %s.tar.gz log.%s' % (name, name))
	c.get('/mnt/logbus_data/game.cn_qd.1/%s.tar.gz' % name, '%s.tar.gz' % name)

@parallel(hosts=roledefs['allgame'])
def start_logbus(c):
	with c.cd('/mnt/ta-logBus/bin'):
		c.run('./logbus start')

@parallel(hosts=roledefs['allgame'])
def stop_logbus(c):
	with c.cd('/mnt/ta-logBus/bin'):
		c.run('./logbus stop')

@parallel(hosts=roledefs['allgame'])
def setup_anti_csv2lua(c):
	Language = 'cn'
	with c.cd('/mnt/release/anti_cheat'):
		with c.cd('game_scripts'):
			ret = c.run(''' cat anti_main.lua|grep "LOCAL_LANGUAGE = '%s'" ''' % Language)
			if ret.exited != 0:
				c.run(''' sed -i "s/LOCAL_LANGUAGE = '.*'/LOCAL_LANGUAGE = '%s'/g" anti_main.lua ''' % Language)
		ret = c.run(''' cat csv2lua.sh|grep "python csv2luaanticheat.py %s" ''' % Language)
		if ret.exited != 0:
			c.run(''' sed -i "s/python csv2luaanticheat.py .*/python csv2luaanticheat.py %s/g" csv2lua.sh ''' % Language)

@parallel(hosts=roledefs['krgame'])
def check_csv2lua_language(c):
	with c.cd('/mnt/release/anti_cheat'):
		c.run(''' cat csv2lua.sh|grep "csv2luaanticheat.py"|awk '{print $3}' ''')

@parallel(hosts=roledefs['xygame'])
def check_disk(c):
	ret = c.run('''df -h|grep "/mnt" ''').stdout.strip()
	print c.original_host, ret

@parallel(hosts=roledefs['cngame'])
def iptables(c):
	ret = c.run('''iptables -L -n -t nat|grep 10022''')
	if ret.exited != 0:
		c.run('''iptables -t nat -A PREROUTING -p tcp --dport 10022 -j REDIRECT --to-ports 22 ''')


@parallel(hosts=roledefs['cngame'])
# @parallel(host='tc-pokemon-cn-02')
def _test(c):
	# with c.cd(get_deploy_path(c)):
	# 	if c.original_host not in ServerIDMap:
	# 		return
	# 	serverIDs = ServerIDMap[c.original_host]
	# 	with c.forward_remote(local_port=3690, local_host=SVN_HOST, remote_port=3690):
	# 		for x in serverIDs:
	# 			dpy = get_deploy_name(x, 'game_server')
	# 			ini = 'supervisord.dir/%s.ini' % dpy
	# 			c.run('svn up %s' % ini)

	# ret = c.run('''python -c "import uuid;print uuid.UUID(int=uuid.getnode()).hex[-12:];" ''')
	ret = c.run('''ip a|grep "scope global"|awk '{print $2}' ''')
	return ret.stdout.strip()

def test():
	result = _test()
	for c in sorted(result.keys(), key=lambda x:(x.original_host.split('-')[-2], int(x.original_host.split('-')[-1]))):
		k = c.original_host
		print 'Host %s' % k
		print '\tHostName %s' % result[c].split('/')[0]
		print ''
		# print "'%s': '%s'," % (k, result[c])

	# url = 'svn://localhost/svn/pokemon_src/release'
	# with c.forward_remote(local_port=SVN_LOCAL_PORT, local_host=SVN_HOST, remote_port=SVN_REMOTE_PORT):
	# 	# with c.cd('/mnt'):
	# 	# 	c.run('svn co svn://localhost/svn/pokemon_src/release release2 --username test --password 123456')
	# 	# 	c.run('rm -r release/.svn')
	# 	# 	c.run('cp -r release2/.svn release/.svn')
	# 	with c.cd('/mnt/release'):
	# 		c.run('svn revert')
	# 		c.run('svn up')
	# 		c.run('svn info')

	# with c.cd(get_deploy_path(c)):
	# 	c.run('supervisorctl status|grep anti')
	# print "test!!!!", c, type(c)
	# result = c.run(''' ifconfig|grep "Bcast" ''').stdout.strip()
	# print 'host', c.host, result
	# print 'original_host', c.original_host
	# print 'config', c.config
	# print c.run('hostname')

	# result = {}
	# with c.cd(get_deploy_path(c)):
	# 	with c.cd('childlog'):
	# 		query = ''' cat cn_130_game_server/2020-09-*.log|grep "11947" |grep "/game/chat" '''
	# 		result = c.run(query.strip()).stdout.strip()

	# with open('chat_result.log', "wb") as fp:
	# 	for c in sorted(result.keys(), key=lambda x: x.original_host):
	# 		k = c.original_host
	# 		ret = result[c]
	# 		# if ret:
	# 		print '-' * 20
	# 		print k, ':'
	# 		# fp.write('\n' + '-' * 20 + '\n')
	# 		# fp.write(k + ':\n')
	# 		ret = ret.encode('utf8')
	# 		print ret
	# 		fp.write(ret + '\n')
	# 		if isinstance(ret, dict):
	# 			for sid, s in ret.iteritems():
	# 				s = s.strip()
	# 				if not s:
	# 					continue
	# 				lst = s.split('\n')
	# 				lst = ['%s %s' % (sid, x) for x in lst]
	# 				print '\n'.join(lst)
	# 				fp.write('\n'.join(lst) + '\n')

def main():

	print('========')
	# r = Connection('heat02', config=config).run('hostname')
	# print type(r)
	# print('command====', r.command)
	# print('stdout====', r.stdout)
	# print('========')

	# print Connection('tc-pokemon-cn-mq', config=config).run('hostname')

	# test(Connection('heat02', config=config))


	group = ThreadingGroup('tc-pokemon-cn-01', config=config)
	result = {}
	for cxn in group:
		print cxn.host, cxn.original_host
		result[cxn.original_host] = _system_all_servers(cxn)
	system_all_servers(result)


if __name__ == '__main__':
	method = sys.argv[1]
	print 'run', method
	mod = sys.modules[__name__]
	func = getattr(mod, method)
	func()
