#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
sys.path.insert(0, '../server/src')

import msgpack
from service_forward import open_forward, objectid2string, string2objectid

def read_explorer(client, name):
	print name
	resp = client.call('DBGetRankSize', 'Rank_fight',  1, 10, service_id=name)
	for v in resp:
		roleID = v['role']['id']
		role = client.call('DBRead', 'Role',  roleID, False, service_id=name)
		explorers = role['model']['explorers']
		if explorers.get(8, {}).get('advance', 0) >= 6 or explorers.get(9, {}).get('advance', 0) >= 6:
			print name, objectid2string(roleID), v['role']['name'], explorers.get(8, {}).get('advance'), explorers.get(9, {}).get('advance')

def read_top100(client, name):
	resp = client.call('DBGetRankSize', 'Rank_fight', 1, 100, service_id=name)
	for v in resp:
		roleID = v['role']['id']
		role = client.call('DBRead', 'Role', roleID, False, service_id=name)
		role = role['model']
		top_cards = role['top_cards'][:10]
		items = role['items']
		print name, 'role', objectid2string(roleID), items.get(850, 0), items.get(851, 0)
		continue

		for i, cardID in enumerate(top_cards):
			card = client.call('DBRead', 'RoleCard', cardID, False, service_id=name)
			card = card['model']
			abilities = card['abilities']
			for k in abilities.keys():
				if k > 10:
					v = abilities[k]
					abilities.pop(k)
					if k > 0:
						k = k % 10
						if k == 0:
							k = 10
						abilities[k] = v
			ret = []
			for j in xrange(1, 11):
				ret.append(abilities.get(j, 0))
			print name, 'role', objectid2string(roleID), i+1, 'card', objectid2string(cardID), card['card_id'], ret,

cards = [
# ('game.cn.1', '5de717535ec29639c547f183', '5ec722df5ec29664d6183a01'),
# ('game.cn.1', '5de720ae5ec29639c547f7f9', '5e2468f65ec2964b58520892'),
# ('game.cn.1', '5de720ae5ec29639c547f7f9', '5edd0ed15ec29611785925d5'),
# ('game.cn.1', '5de720ae5ec29639c547f7f9', '5de772be5ec29639c5489fb6'),
# ('game.cn.1', '5de720ae5ec29639c547f7f9', '5e6e2e355ec2961d6eba7039'),
# ('game.cn.1', '5de797235ec29639c54929f3', '5e25016b5ec2964b58520ca8'),
# ('game.cn.1', '5de717535ec29639c547f183', '5eb4f8f25ec29613e147dc9d'),
# ('game.cn.1', '5de730305ec29639c54808e2', '5decf1ff5ec2962e775bcf83'),
# ('game.cn.1', '5de720ae5ec29639c547f7f9', '5defa2265ec296704a5a7c93'),
# ('game.cn.2', '5de7a2be5ec2967a23be46b1', '5deb2cbe5ec2962eaf8dc40f'),
# ('game.cn.2', '5dea45975ec2962eaf8d6d68', '5dfc3f0f5ec2967da0290d1c'),
# ('game.cn.2', '5de7a2be5ec2967a23be46b1', '5f01dc4e5ec2962b98fb11a0'),
# ('game.cn.2', '5de7a2be5ec2967a23be46b1', '5e6e2e105ec2961d7d5358e7'),
# ('game.cn.3', '5e0aacb35ec29617e7ea0904', '5e245e3b5ec2964b775e347d'),
# ('game.cn.8', '5e7852ba6acf9464f91cc327', '5eb803a86acf94272d914eb2'),
# ('game.cn.11', '5e96a0ef4433543345c7b351', '5ec6f3094433545696c035b2'),
# ('game.cn.15', '5e79975997908e44deee9523', '5e7a0dd297908e44deef9ac0'),
# ('game.cn.18', '5e79dc9ede4d356ee275d907', '5e7c3da0de4d356ee278029b'),
# ('game.cn.18', '5e79d3f3de4d356ee275932f', '5e7c7b0bde4d356ee27815b8'),
# ('game.cn.18', '5e79dc9ede4d356ee275d907', '5f01dcb5de4d353b7a1334d8'),
# ('game.cn.24', '5e7af2a3d046a55ea812ba88', '5e93182dd046a544d25d0880'),
# ('game.cn.24', '5e7af2a3d046a55ea812ba88', '5eb80253d046a540d5a92839'),
# ('game.cn.24', '5e7af2a3d046a55ea812ba88', '5e834804d046a554102bc76a'),
# ('game.cn.32', '5e7c2ed065beac45bc39d77d', '5e7c72b865beac45bc3b7d8a'),
# ('game.cn.39', '5e7d620063c36c4bbfae46e0', '5ea213e363c36c31849b5347'),
# ('game.cn.42', '5e7dd292a4e861520c90f130', '5e80922ea4e8610cfba8e6d9'),
# ('game.cn.42', '5e7dcfe8a4e861520c90e839', '5e7e37c2a4e861520c91ec2b'),
# ('game.cn.67', '5e8eb36c93bb6f39b061fb3a', '5e8ee06993bb6f39b0626e73'),
# ('game.cn.68', '5e8ecc7963c36c4a111bc332', '5e933e2963c36c67bbde4f52'),
# ('game.cn.68', '5e8ecc7963c36c4a111bc332', '5ec74f4863c36c0f3653f53e'),
# ('game.cn.68', '5e8ecc7963c36c4a111bc332', '5ea2636863c36c31dc57fe48'),
# ('game.cn.91', '5e9a92ef93bb6f5d4b0033f5', '5e9aca2c93bb6f5d4b00ad27'),
# ('game.cn.164', '5ec64c9ce7661f11b4281f7e', '5ec6f2d8e7661f41ecb0e5d6'),
# ('game.cn.189', '5ecfce02a4e861694123df06', '5ecfe94ba4e8616941242c0c'),
# ('game.cn.194', '5ed22364a7812e62a6a5b18a', '5ed43058a7812e62a6a941de'),
# ('game.cn_qd.1', '5e7d5fb65c17365319c02145', '5eb802c15c17362e93ad1f27'),
# ('game.cn_qd.2', '5e7d5ea33557f9681c26353d', '5eb804683557f94a595009ce'),
# ('game.cn_qd.2', '5e7d5ea33557f9681c26353d', '5e7eff543557f9681c298499'),
('game.cn_qd.2', '5e7d5ea33557f9681c26353d', '5ea220ab3557f905f96eb49c'), # 5ea220ab3557f905f96eb49c
# ('game.cn_qd.2', '5e7d5f553557f9681c2672f3', '5e7d7b873557f9681c277b05'),
# ('game.cn_qd.2', '5e7d5ea33557f9681c26353d', '5e85ea273557f92e75b66e14'),
# ('game.cn_qd.2', '5e7d5ea33557f9681c26353d', '5ec732bb3557f939f1660bef'),
# ('game.cn_qd.4', '5e7d633d3359346c4b545ac9', '5eb802de3359346dbf29b4f6'),
# ('game.cn_qd.6', '5e7d67d7794609789573b10d', '5e85ea12794609199d27924e'),
# ('game.cn_qd.6', '5e7d67d7794609789573b10d', '5eb8022179460977de895caa'),
# ('game.cn_qd.8', '5e7d6e663557f90c1955fd15', '5e83ca253557f92e852150a6'),
# ('game.cn_qd.14', '5e7d81bb3557f93d59ea75e3', '5e8168ea3557f92e9967bcaf'),
# ('game.cn_qd.35', '5e7e309538984811a07520f5', '5e85eac538984848ac16e0e9'),
# ('game.cn_qd.35', '5e7e309538984811a07520f5', '5e7eee0438984811a076ae75'),
# ('game.cn_qd.41', '5e7ecf748038a81468226d1b', '5e9b91bd8038a845b4a34e5a'),
# ('game.cn_qd.42', '5e7edcb5f40a310f76cb6451', '5e842184f40a310f0b5fef91'),
# ('game.cn_qd.47', '5e7f0fd69093b012ad004152', '5e853bdb9093b064939d4c1c'),
# ('game.cn_qd.48', '5e7f12753359345ee43bda25', '5e82b01f335934276a212f3a'),
# ('game.cn_qd.57', '5e7fbc6f3557f92ecccaa812', '5e7fc62f3557f92ecccab9bb'),
# ('game.cn_qd.57', '5e7fbc6f3557f92ecccaa812', '5eb802a73557f94ab4d6d318'),
# ('game.cn_qd.60', '5e80057e2bf95829553044e9', '5e801c4e2bf958295531061f'),
# ('game.cn_qd.103', '5e821e5a36d55f4f9518babd', '5e8224ab36d55f4f9518f5c9'),
# ('game.cn_qd.104', '5e822c34241dcc4e330a3622', '5e88bfd4241dcc2cf46e2e6a'),
# ('game.cn_qd.107', '5e829cef884cae57bab62bbe', '5e845e96884cae57bab7530f'),
# ('game.cn_qd.170', '5e85e9c7cc3c972b0e8211f1', '5e86fbb8cc3c97726033d88a'),
# ('game.cn_qd.171', '5e85f85f89d4d42a09043107', '5e861cde89d4d42a09056a54'),
# ('game.cn_qd.227', '5e8b023571bbac5192e08b40', '5e93184d71bbac32f4367f48'),
# ('game.cn_qd.250', '5ebd06133359346e3b984c55', '5efe5c6f3359343f2afdd19e'),
# ('game.cn_qd.267', '5e8ef363db4c2a13797824a1', '5e8efb3ddb4c2a1379788038'),
# ('game.cn_qd.281', '5e906b6dcad05a1add45c05f', '5ec6f2b7cad05a6c3710339a'),
# ('game.cn_qd.283', '5e90930ced560935571dd5a0', '5ec6fadeed56093707a39294'),
# ('game.cn_qd.286', '5e91312bfb8be81491c496e5', '5eb80274fb8be87d9e85b54e'),
# ('game.cn_qd.296', '5e91f52864448c3eda8a364c', '5ea4c67c64448c4c620df2c8'),
# ('game.cn_qd.301', '5e92c0235ae2623a5a77e685', '5e93eaf35ae2623a5a78a645'),
# ('game.cn_qd.306', '5e9311b45167c5458d173bc0', '5e98ee295167c529070a1d52'),
# ('game.cn_qd.333', '5e95b7af6e961433f4c7e353', '5e96b5106e961433f4c92783'),
# ('game.cn_qd.347', '5e9701ee6e9614340a998d05', '5e9741da6e9614340a9ae2a7'),
# ('game.cn_qd.352', '5e97ceb164448c3f1c8c2451', '5e982b7264448c3f1c8d5049'),
# ('game.cn_qd.388', '5e9b30ec856f0048190b0154', '5e9e3227856f0048190d6098'),
# ('game.cn_qd.403', '5e9d0d3c26dc8771a14a79de', '5eb8028726dc877064627278'),
# ('game.cn_qd.447', '5ea2f677d901384e96a41a99', '5eb8036ad901384114928531'),
# ('game.cn_qd.447', '5ea2f677d901384e96a41a99', '5ea3e773d901384e96a5965e'),
# ('game.cn_qd.456', '5ea46532c7ecc71325f96055', '5eeedb89c7ecc7787e1c8857'),
# ('game.cn_qd.491', '5eaae5d3d901385bdb84c7db', '5eab6613d9013824a0cd9b7d'),
# ('game.cn_qd.500', '5eac4104fb8be8772b2b246d', '5eb801eafb8be87e0abad969'),
('game.cn_qd.534', '5eb2af067f76107be3644a4f', '5eb48fa47f76107beea920cd'), # 5eb48fa47f76107beea920cd
# ('game.cn_qd.535', '5eb2e54ab97cb22e00d2dc06', '5eb5ddaab97cb230e537a6f9'),
# ('game.cn_qd.555', '5eb740f63359346e6c48559f', '5efe79803359343f66401862'),
# ('game.cn_qd.569', '5eb9ac7936d55f28e5b83416', '5ec13c8336d55f7928ea423e'),
# ('game.cn_qd.569', '5eb9ac7936d55f28e5b83416', '5eebd83036d55f68c97b2cf1'),
# ('game.cn_qd.569', '5eb9ac7936d55f28e5b83416', '5f02463c36d55f03d5d0d281'),
# ('game.cn_qd.587', '5ebc13871c903a6d958454b5', '5eebe3f01c903a02d07e2ba8'),
# ('game.cn_qd.643', '5ec512ea820c487ba0e33da6', '5ec526c5820c487ba0e3f538'),
# ('game.cn_qd.647', '5ec5fd7fd64df33dc4fe8c72', '5efea504d64df36eb03aa7b7'),
# ('game.cn_qd.669', '5ec93f3c241dcc55e30a82f3', '5ec98ce9241dcc55e30b8304'),
# ('game.cn_qd.705', '5ed04ed164448c7d6c45f0cb', '5ed0651e64448c7d6c4669b1'),
# ('game.cn_qd.705', '5ed04ed164448c7d6c45f0cb', '5eebd70b64448c55475759e7'),
# ('game.cn_qd.705', '5ed04ed164448c7d6c45f0cb', '5edcec1864448c4cdc6de0aa'),
# ('game.cn_qd.707', '5ed0cae87b474e6e5bcf514f', '5ed471677b474e6e5bd0227f'),
# ('game.cn_qd.710', '5ed107cbd901384649b40315', '5ed8f77bd901384649b7955c'),
# ('game.cn_qd.746', '5ed9557f89d4d42bb5ea7d6e', '5ed95fdf89d4d42bb5ea83c3'),
# ('game.cn_qd.774', '5edf3148c7ecc702c86dc922', '5efed135c7ecc772b7d95d34'),
# ('game.cn_qd.774', '5edf3148c7ecc702c86dc922', '5f111bb7c7ecc74ea8ac59f2'),
# ('game.cn_qd.774', '5edf3148c7ecc702c86dc922', '5ee05fd1c7ecc702c86e9cd6'),
# ('game.cn_qd.814', '5ee70a806abd9a2956046d3f', '5f131fb26abd9a6ea6593d64'),
# ('game.cn_qd.837', '5eecc0747b474e49f1bb11e0', '5eed6c337b474e49f1bc86f5'),
# ('game.cn_qd.916', '5ef946e3f00e4612b60b9d1e', '5efa38e8f00e4612b60c9312'),
]

def multi_future(d, rasie_exc=False):
	keys = list(d.keys())
	d = d.values()
	unfinished_d = set(d)

	future = Future()
	if not d:
		future.set_result({} if keys is not None else [])
	def callback(f):
		unfinished_d.remove(f)
		if not unfinished_d:
			result_list = []
			has_except = False
			for index, i in enumerate(d):
				try:
					result_list.append(i.result())
				except Exception as e:
					has_except=True
					result_list.append(e)
					# logger.exception("multi_future error, %s", keys[index])
			if rasie_exc and has_except:
				for result in result_list:
					if isinstance(result, Exception):
						future.set_exception(result)
						break
			else:
				future.set_result(dict(zip(keys, result_list)))
	for f in d:
		f.add_done_callback(callback)
	return future

def save_play(name, id, data):
	data = [name, msgpack.packb(data, use_bin_type=True)]
	data = msgpack.packb(data, use_bin_type=True)
	with open('card_3631/%s_%s.play' % (name, id), 'wb') as fp:
		fp.write(data)

import itertools
from tornado.ioloop import IOLoop
from tornado.gen import coroutine, Return, sleep
from tornado.concurrent import Future

import copy
def unpack(argsD):
	argsD = copy.deepcopy(argsD)
	type1 = argsD.pop('type1', None)
	type2 = argsD.pop('type2', None)
	if type1:
		for k, v in type1.iteritems():
			argsD[k] = v
	if type2:
		for k, v in type2.iteritems():
			argsD[k] = v
	return argsD

def online():
	with open_forward('cn') as client:

		@coroutine
		def run():

			crossAndGameKeyMap = {
				'crossarena.cn_qd.1': 'game.cn_qd.1',
				'crossarena.cn_qd.2': 'game.cn_qd.2',
				'crossarena.cn_qd.3': 'game.cn_qd.41',
				'crossarena.cn_qd.4': 'game.cn_qd.42',
				'crossarena.cn_qd.5': 'game.cn_qd.103',
				'crossarena.cn_qd.6': 'game.cn_qd.104',
				'crossarena.cn_qd.7': 'game.cn_qd.163',
				'crossarena.cn_qd.8': 'game.cn_qd.164',
				'crossarena.cn_qd.9': 'game.cn_qd.215',
				'crossarena.cn_qd.10': 'game.cn_qd.216',
				'crossarena.cn_qd.11': 'game.cn_qd.269',
				'crossarena.cn_qd.12': 'game.cn_qd.270',
				'crossarena.cn_qd.13': 'game.cn_qd.323',
				'crossarena.cn_qd.14': 'game.cn_qd.324',
				'crossarena.cn_qd.15': 'game.cn_qd.373',
				'crossarena.cn_qd.16': 'game.cn_qd.374',
				'crossarena.cn_qd.17': 'game.cn_qd.421',
				'crossarena.cn_qd.18': 'game.cn_qd.422',
				'crossarena.cn_qd.19': 'game.cn_qd.465',
				'crossarena.cn_qd.20': 'game.cn_qd.466',
				'crossarena.cn_qd.21': 'game.cn_qd.505',
				'crossarena.cn_qd.22': 'game.cn_qd.506',
				'crossarena.cn_qd.23': 'game.cn_qd.545',
				'crossarena.cn_qd.24': 'game.cn_qd.563',
				'crossarena.cn_qd.25': 'game.cn_qd.564',
				'crossarena.cn_qd.26': 'game.cn_qd.565',
				'crossarena.cn_qd.27': 'game.cn_qd.566',
			}

			head = []
			for v in ['排名','玩家区服','玩家id','玩家等级','名字','竞技场阵容1','竞技场阵容1战力','竞技场阵容2','竞技场阵容2战力']:
				head.append(v.decode('utf-8').encode('gbk'))
			data = []
			for crossKey in sorted(crossAndGameKeyMap.iterkeys()):
				gameKey = crossAndGameKeyMap[crossKey]
				data.append([crossKey])
				data.append(head)
				storageKey = gameKey.replace('game', 'storage')
				resp = yield client.call_async('DBReadBy', 'CrossArenaGameGlobal', {'key': gameKey}, service_id=storageKey)
				model = resp['models'][0]
				topNum = 100
				tops = model['last_ranks'][:topNum]
				for item in tops:
					recordDBID = item['record_db_id']
					recordKey = item['game_key'].replace('game', 'storage')
					respRole = yield client.call_async('DBRead', 'CrossArenaRecord', recordDBID, False, service_id=recordKey)
					record = respRole['model']

					cardAttrs = record['card_attrs']
					cards = record['cards']
					troops = {
						1: {'cards': [], 'fp': 0},
						2: {'cards': [], 'fp': 0}
					}
					for troopIdx in troops.iterkeys():
						for cardDBID in cards[troopIdx]:
							if cardDBID not in cardAttrs:
								continue
							card = cardAttrs[cardDBID]
							troops[troopIdx]['cards'].append(card['card_id'])
							troops[troopIdx]['fp'] += card['fighting_point']

					try:
						name = item['name'].decode('utf-8').encode('gbk')
					except:
						name = item['name']
					item = [
						item['rank'], item['game_key'], objectid2string(item['role_db_id']), item['level'],
						name,
						troops[1]['cards'], troops[1]['fp'],
						troops[2]['cards'], troops[2]['fp'],
					]
					print crossKey, item
					data.append(item)

				data.append([])

			import csv
			with open('cross_area_rank.csv', 'w') as f:
				csvW = csv.writer(f)
				for item in data:
					csvW.writerow(item)

			# roles = {} # {id: (uid, name)}
			# for key, roleid, cardid in cards:
			# 	if roleid not in roles:
			# 		resp = yield client.call_async('DBRead', 'Role', string2objectid(roleid), False, service_id=key.replace('game', 'storage'))
			# 		role = resp['model']
			# 		roles[roleid] = (role['uid'], role['name'])

			# 	if True:
				# try:
					# resp = yield client.call_async('DBRead', 'RoleCard', string2objectid(cardid), False, service_id=key.replace('game', 'storage'))
					# card = resp['model']
					# nvalue = card['nvalue']
					# print key, roleid, roles[roleid][0], roles[roleid][1], cardid, card['card_id'], card['nvalue']
				# except:
					# print '!!! error', key, roleid


			# resp = yield client.call_async('DBRankClearRole', string2objectid('5ea17d6bd64df35238a68e01'), ['Rank_yybox'], service_id='storage.cn_qd.439')
			# ids = ['5e7b3201d046a55ea813fc10', '5e7b7330d046a55ea81434bd', '5e7b763ed046a55ea814370f', '5e7b51ead046a55ea81419a2', '5ea20eb7d046a579258646c8', '5ea20eb7d046a579258646c8', '5e93182dd046a544d25d0880', '5e834804d046a554102bc76a', '5e93182dd046a544d25d0880', '5ec6f1ded046a5429e0ee70f', '5eb80253d046a540d5a92839', '5edced77d046a568f73fd6b0', '5eb80253d046a540d5a92839', '5edced77d046a568f73fd6b0', '5e834804d046a554102bc76a']
			# for id in ids:
			# 	resp = yield client.call_async('DBRead', 'RoleCard', string2objectid(id), False, service_id='storage.cn.24')
			# 	print id, resp['model']['card_id']

			# from datetime import datetime
			# award = {}
			# resp = yield client.call_async('DBReadBy', 'Mail', {"role_db_id": string2objectid('5e8adb1c63c36c6159c998fb'), "deleted_flag": False}, service_id='storage.cn.60')
			# for mail in resp['models']:
			# 	print objectid2string(mail['id']), mail['subject'], mail['time'], datetime.fromtimestamp(mail['time']), unpack(mail['attachs'])
			# 	for k, v in unpack(mail['attachs']).iteritems():
			# 		award[k] = award.get(k, 0) + v

			# 	ret = yield client.call_async('DBUpdate', 'Mail', mail['id'], {"deleted_flag": True}, True, service_id='storage.cn.60')
			# 	print ret

			# print len(resp['models'])
			# print award
			# {4000: 70, 20741: 3, 'gold': 1069000, 'coin1': 920, 'coin2': 670, 21421: 2, 'rmb': 310, 20721: 3, 6003: 18, 6004: 6, 950: 2, 21501: 3}

			# keys = []
			# keys += ['storage.cn.%d' % i for i in xrange(1, 180+1)]
			# keys += ['storage.cn_qd.%d' % i for i in xrange(1, 680+1)]

			# futures = {}
			# for key in keys:
			# 	for date in [20200525, 20200524, 20200523]:
			# 		for round in ['final1', 'final2', 'final3']:
			# 			name = '%s_%s_%s' % (key, date, round)
			# 			futures[name] = _run(key, 20200525, 'final1')
			# yield multi_future(futures)

		IOLoop.current().run_sync(run)


if __name__ == "__main__":
	online()
