#!/usr/bin/python
# -- coding: utf-8 --

import sys
sys.path.append('../server/src')

from service_forward import *

# key, unionName, unionID
UNION_LIST = [
('game.cn.188'	,'5ece6aaf63c36c410a28197f'),
('game.cn.192'	,'5ed1ac1fe7661f3c32b0921d'),
('game.cn.192'	,'5ed18886e7661f3c32b058f4'),
('game.cn.192'	,'5ed1b731e7661f3c32b0b16c'),
('game.cn.192'	,'5ed1b731e7661f3c32b0b16c'),
('game.cn.192'	,'5ed1ba6ee7661f3c32b0bee2'),
('game.cn.192'	,'5ed1ba6ee7661f3c32b0bee2'),
('game.cn.193'	,'5ed1fb766cbae61287e4e797'),
('game.cn.193'	,'5ed1fb766cbae61287e4e797'),
('game.cn.193'	,'5ed1f8c86cbae61287e4d80c'),
('game.cn.193'	,'5ed1ec326cbae61287e49683'),
('game.cn.193'	,'5ed1ec326cbae61287e49683'),
('game.cn.193'	,'5ed1f9de6cbae61287e4def6'),
('game.cn.193'	,'5ed1f9e56cbae61287e4df2a'),
('game.cn.194'	,'5ed22d11a7812e62a6a5d321'),
('game.cn.194'	,'5ed22f56a7812e62a6a5dc4d'),
('game.cn.194'	,'5ed22f56a7812e62a6a5dc4d'),
('game.cn.196'	,'5ed3435097908e73be7b15e2'),
('game.cn_qd.710'	,'5ed12a04d901384649b54c72'),
('game.cn_qd.710'	,'5ed11603d901384649b492a5'),
('game.cn_qd.710'	,'5ed10e6ad901384649b44053'),
('game.cn_qd.711'	,'5ed1b1be75cfd30599b72031'),
('game.cn_qd.711'	,'5ed1b1be75cfd30599b72031'),
('game.cn_qd.712'	,'5ed1b8c8d64df348f1a38562'),
('game.cn_qd.712'	,'5ed1b8c8d64df348f1a38562'),
('game.cn_qd.712'	,'5ed1bb1ed64df348f1a3a3a4'),
('game.cn_qd.712'	,'5ed1b7d6d64df348f1a37923'),
('game.cn_qd.712'	,'5ed1c51fd64df348f1a44e22'),
('game.cn_qd.712'	,'5ed1c51fd64df348f1a44e22'),
('game.cn_qd.712'	,'5ed1b8dbd64df348f1a38651'),
('game.cn_qd.712'	,'5ed1bc15d64df348f1a3b30c'),
('game.cn_qd.713'	,'5ed1cf3655d0270b85287b4e'),
('game.cn_qd.713'	,'5ed1d9b155d0270b85293317'),
('game.cn_qd.713'	,'5ed1d9b155d0270b85293317'),
('game.cn_qd.713'	,'5ed1d0ae55d0270b852892f9'),
('game.cn_qd.713'	,'5ed1d2a355d0270b8528b3d4'),
('game.cn_qd.713'	,'5ed1d2a355d0270b8528b3d4'),
('game.cn_qd.714'	,'5ed1e8f209582f4e877938dd'),
('game.cn_qd.714'	,'5ed1e8f209582f4e877938dd'),
('game.cn_qd.714'	,'5ed1ea2609582f4e87794ab7'),
('game.cn_qd.714'	,'5ed1e81d09582f4e87792b76'),
('game.cn_qd.714'	,'5ed1fa4209582f4e877a3b03'),
('game.cn_qd.714'	,'5ed2034109582f4e877a8e0c'),
('game.cn_qd.715'	,'5ed204145eed694b02bdea1a'),
('game.cn_qd.715'	,'5ed203555eed694b02bddbc6'),
('game.cn_qd.715'	,'5ed203565eed694b02bddbd2'),
('game.cn_qd.715'	,'5ed203565eed694b02bddbd2'),
('game.cn_qd.715'	,'5ed20c265eed694b02be7322'),
('game.cn_qd.716'	,'5ed21835789f29298fe735d4'),
('game.cn_qd.716'	,'5ed21944789f29298fe7490d'),
('game.cn_qd.717'	,'5ed259e13557f9578327505d'),
('game.cn_qd.717'	,'5ed259e13557f9578327505d'),
('game.cn_qd.717'	,'5ed256a03557f95783272797'),
('game.cn_qd.717'	,'5ed25bd63557f95783276517'),
('game.cn_qd.717'	,'5ed25afc3557f95783275bda'),
('game.cn_qd.718'	,'5ed290679093b0210c8565e3'),
('game.cn_qd.718'	,'5ed290679093b0210c8565e3'),
('game.cn_qd.719'	,'5ed307b33359347ff36e28af'),
('game.cn_qd.720'	,'5ed320eb2bf9580f43c8beae'),
('game.cn_qd.721'	,'5ed3333179460902b24ff788'),
('game.cn_qd.721'	,'5ed335a079460902b2501750'),
('game.cn_qd.722'	,'5ed34dd31afd0042036fd6ab'),
('game.cn_qd.722'	,'5ed36ef21afd004203712128'),
('game.cn_qd.723'	,'5ed365258038a84c887ebed2'),
('game.cn_qd.724'	,'5ed3866cf40a3171142cc107'),
]

UNION_SET = set(UNION_LIST)

print 'UNION_LIST', len(UNION_LIST), 'UNION_SET', len(UNION_SET)
for t in UNION_SET:
	try:
		gkey, unionID = t
	except:
		print t
		raise


# key, roleID
ROLE_LIST = [

]


# accountID
ACCOUNT_LIST = [
'5ece61dcbb0b08245c22ab2d',
'5ecf0231bb0b08245c22c2aa',
'5ecf24e7bb0b08245c22cae6',
'5ed1b41cbb0b08245c237dde',
'5ed1b41fbb0b08245c237de0',
'5ec882ebbb0b08245c202f34',
'5ec78d65bb0b08245c1fc2bf',
'5ec882f4bb0b08245c202f41',
'5ec39ce4bb0b08245c1e6a60',
'5ed1f3a2bb0b08245c23aafa',
'5ecf24e7bb0b08245c22cae6',
'5ed1e883bb0b08245c23a2c1',
'5ed1f3a2bb0b08245c23ab00',
'5ed1f3a2bb0b08245c23aafe',
'5ed1d9a2bb0b08245c23972a',
'5ed22bb6bb0b08245c23ce81',
'5ed228a9bb0b08245c23ccb5',
'5ed33c1dbb0b08245c244030',
'5ed11f4ebb0b08245c2363a9',
'5ece0793bb0b08245c228754',
'5ecf5a71bb0b08245c22dd1f',
'5ed1a9e1bb0b08245c2379da',
'5ed1b7eebb0b08245c238005',
'5ed1b594bb0b08245c237eb7',
'5ed1c2cbbb0b08245c238719',
'5ece128cbb0b08245c228b36',
'5ec514d0bb0b08245c1ee738',
'5ed12504bb0b08245c2365d5',
'5ed12504bb0b08245c2365cf',
'5e9ec79dbb0b0837f5d02596',
'5ed1b397bb0b08245c237d9a',
'5e9ebfc0bb0b0837f5d01f82',
'5ed1d4ddbb0b08245c23939c',
'5ed1d589bb0b08245c239445',
'5ed1ccd2bb0b08245c238dba',
'5ed12505bb0b08245c2365d7',
'5ece0793bb0b08245c228756',
'5ed1da50bb0b08245c23979b',
'5ed1e656bb0b08245c23a0ab',
'5ed1ca88bb0b08245c238c03',
'5ed1ca83bb0b08245c238bfd',
'5ecf68bebb0b08245c22e150',
'5ec515f7bb0b08245c1ee7ca',
'5ed1ca88bb0b08245c238c03',
'5e9ec463bb0b0837f5d02370',
'5ed12504bb0b08245c2365d0',
'5ed1d3dbbb0b08245c2392dd',
'5ecb937fbb0b08245c21c846',
'5ed0de11bb0b08245c234273',
'5e9f0ed2bb0b0837f5d056a5',
'5ed12504bb0b08245c2365cd',
'5ed12504bb0b08245c2365d1',
'5ed1ca88bb0b08245c238c03',
'5ed12046bb0b08245c23641a',
'5eb6160abb0b08245c18b9b3',
'5eb52aaabb0b08245c18598f',
'5ec8f50fbb0b08245c209579',
'5ec51461bb0b08245c1ee709',
'5ec12c0abb0b08245c1da23d',
'5ed330dcbb0b08245c243723',
'5ea58dadbb0b08608b47f41d',
'5ed1f050bb0b08245c23a8a7',
'5ed35ecfbb0b08245c245a72',
'5ed34fecbb0b08245c244f2c',
'5ed11f4ebb0b08245c2363aa',
]

def clean_union_intro():
	with open_forward('cn') as client:
		for t in UNION_SET:
			gkey, unionID = t
			print gkey, 'gmGetUnionInfo', unionID
			union = client.call('gmGetUnionInfo', string2objectid(unionID), service_id=gkey)
			roleID = objectid2string(union['chairman_db_id'])
			print union['intro']

			domains = gkey.split('.')
			domains[0] = 'union'
			ukey = '.'.join(domains)
			print ukey, unionID, roleID
			resp = client.call('ModifyIntro', string2objectid(unionID), string2objectid(roleID), "欢迎大家加游戏群：554802325，一起聊天打屁~", service_id=ukey)
			print resp['sync']['union'].keys()


def role_abandon():
	with open_forward('cn') as client:
		for t in ROLE_LIST:
			gkey, roleID = t
			print gkey, roleID
			resp = client.call('gmRoleAbandon', string2objectid(roleID), "disable", True, service_id=gkey)
			print resp


def account_disable():
	with open_forward('cn') as client:
		# resp = client.call('AccountQuery', string2objectid('5e8dcfd1bb0b0862f409825f'), service_id='accountdb.cn.1')
		# resp = client.call('AccountQueryByName', 'tc_qd_10012141', service_id='accountdb.cn.1')
		# print resp

		for accountID in ACCOUNT_LIST:
			print accountID
			resp = client.call('AccountDisable', string2objectid(accountID), True, service_id='accountdb.cn.1')
			print resp


if __name__ == "__main__":
	# role_abandon()
	account_disable()
	clean_union_intro()
