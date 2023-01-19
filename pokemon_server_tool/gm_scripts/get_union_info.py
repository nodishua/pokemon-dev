#!/usr/bin/python
# -*- coding: utf-8 -*-

from service_forward import *


KEY = 'cn_qd'
ID_START = 200
ID_END = 200
UNION_RANK = 20

def do():
	print 'KEY, ID_START, ID_END =', KEY, ID_START, ID_END
	with open_forward() as client:

		for i in xrange(ID_START, ID_END+1):
			print '='*10
			key = 'game.%s.%d' % (KEY, i)
			print key

			resp = client.call('gmGetGameRank', 'union', service_id=key)
			rank = resp['view']['rank'][:UNION_RANK]
			for info in rank:
				# print info.keys()
				print '-'*10
				unionID = info['id']
				print key, info['name'], info['level'], info['members'], info['chairman_name'], info['intro'], objectid2string(info['id'])
				union = client.call('gmGetUnionInfo', unionID, service_id=key)
				# print union.keys()
				chairman_db_id, vice_chairmans = union['chairman_db_id'], union['vice_chairmans']

				role = client.call('gmGetRoleInfo', chairman_db_id, service_id=key)
				# sum([d.get('star', 0) for gateID, d in self.gate_star.iteritems() if gateID in csv.scene_conf and csv.scene_conf[gateID].sceneType in types])
				gateStarSum = sum([d.get('star', 0) for gateID, d in role['gate_star'].iteritems()])
				print key, info['name'], objectid2string(info['id']), '会长:', 'name', role['name'], 'level', role['level'], 'vip', role['vip_level'], 'star', gateStarSum, 'fight', role['battle_fighting_point'], 'role', objectid2string(chairman_db_id), 'account', objectid2string(role['account_id'])
				for dbid in vice_chairmans:
					role = client.call('gmGetRoleInfo', dbid, service_id=key)
					gateStarSum = sum([d.get('star', 0) for gateID, d in role['gate_star'].iteritems()])
					print key, info['name'], objectid2string(info['id']), '副会长:', 'name', role['name'], 'level', role['level'], 'vip', role['vip_level'], 'star', gateStarSum, 'fight', role['battle_fighting_point'], 'role', objectid2string(dbid), 'account', objectid2string(role['account_id'])

			


if __name__ == "__main__":
	# print sys.argv
	helpcmd = True if len(sys.argv) > 1 and sys.argv[1].strip() == '-h' else False
	if len(sys.argv) > 1 and not helpcmd:
		KEY, ID_START, ID_END = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
		try:
			UNION_RANK = int(sys.argv[4])
		except:
			pass
		do()
	else:
		print '功能： 获取相关区服公会信息'
		print '参数： game_key_prefix id_start id_end top'
		print '例子： cn_qd 200 230 10'
		print '解释： 获取cn_qd渠道，200-230服，排名前10的工会信息（10不填默认为排名前20的工会）'