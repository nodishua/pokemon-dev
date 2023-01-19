# coding:utf8
import json
import os
import random
import subprocess
import traceback
from datetime import datetime

import bson
import msgpack
import pymongo
import shutil
from contextlib import contextmanager

from defines import MongoDefs, DumpPath

@contextmanager
def open_mongo(uri):
	client = pymongo.MongoClient(uri)
	yield client
	client.close()

def split_name(uri):
	uri = uri.split('?')[0]
	return uri.split('/')[-1]

# 初始化备份目录
def init_dir():
	# 清空备份目录
	if os.path.exists(DumpPath):
		shutil.rmtree(DumpPath)
	# 初始化备份目录
	if not os.path.exists(DumpPath):
		os.makedirs(DumpPath)

exclude_collections = [
	'ArenaPlayRecord',
	'CraftPlayRecord',
	# 'UnionFightPlayRecord',

	'HorseRaceGlobal',  # 活动-赛马数据(不会在玩法开放时合服)
	'TinyRank',  # 活动副本小排行榜
	'GMYYConfig',  # 运营动态配置
	'MailGlobal',  # 全局邮件
	'MessageGlobal',  # 全局消息
	'ArenaGlobalHistory',  # 竞技场每日排名的历史
	'CloneGlobal',  # 元素挑战全局数据
	'CloneRoom'  # 元素挑战的房间
]
excludes = ['--excludeCollection=' + x for x in exclude_collections]
excludes = ' '.join(excludes)

# dump 备份mongo数据
def mongo_dump_data(keys):
	for key in keys:
		uri = MongoDefs[key]
		s = '''mongodump --uri "{uri}" {excludes} --gzip -o {dump_path}'''.format(uri=uri, excludes=excludes, dump_path=DumpPath)
		print(s)
		subprocess.check_call(s.split(' '))

# restore 恢复mongo数据
def mongo_restore_data(dest, keys):
	uri = MongoDefs[dest]
	# 开始合服，不恢复索引（服务重启后会创建），所以先直接全部恢复到目标db
	for key in keys:
		name = split_name(MongoDefs[key])
		path = os.path.join(DumpPath, name)
		s = '''mongorestore --noIndexRestore --uri "{uri}" --gzip -d {database} {dump_path}'''.format(uri=uri, database=split_name(uri), dump_path=path)
		print(s)
		subprocess.check_call(s.split(' '))

# 进度条
def get_progress_bar(name, max_val):
	value = [0]

	def print_progress(now):
		p = int(now * 1.0 / max_val * 100)
		if value[0] != p:
			value[0] = p
			print '\r{operating}: [{process}] {rate}%'.format(operating=name, process='#'*p+' '*(100-p), rate=p),
			if now >= max_val:
				print '\n'
	return print_progress


# =======================


# 构建合服后的 name
def comb_role_name(name, area):
	suffix = '.s%d' % area
	if name.endswith(suffix):
		return name
	return name + suffix


# 删除不必要的集合（启动服务后会自动重建）
def modify_collection_data(dst_conn, col_list):
	print('del collection start')
	for col in col_list:
		dst_conn.drop_collection(col)
		print(col + ' droped')
	print('del collection done')

# 修改role的数据
def modify_role_data(db):
	uid = 10001
	collection = db['Role']
	roles = collection.find({}, {'_id': 1, 'uid': 1, 'name': 1, 'area': 1})
	count = roles.count()
	progress_bar = get_progress_bar('modify_role_data', count)
	now_count = 0
	# 从 uid 开始写入
	for role in roles:
		collection.update({'_id': role['_id']},
						{'$set': {
							'uid': uid,
							'name': comb_role_name(role['name'], role['area']),
							'clone_room_db_id': '',  # 所选择的克隆人房间(元素挑战房间)
							'clone_deploy_card_db_id': '',  # 元素挑战上阵卡牌ID
							'clone_daily_be_kicked_num': 0,  # 元素挑战每日被踢次数
							'clone_room_create_time': 0,  # 元素挑战房间创建时间
							'global_mail_idx': 0, # 收取全局邮件的游标
						}})
		uid += 1
		now_count += 1
		progress_bar(now_count)
	db['IncID'].find_one_and_update({'_id': 'Role'}, {"$set": {'id': uid-1}}, upsert=True)

# 修改union的数据
def modify_union_data(db):
	uid = 1
	collection = db['Union']
	unions = collection.find({}, {'_id': 1, 'uid': 1, 'name': 1, 'area': 1})
	count = unions.count()
	progress_bar = get_progress_bar('modify_union_data', count)
	names = set([])
	# 从 uid 开始写入
	for union in unions:
		name = union['name']
		if name in names: # 存在重名公会
			name = comb_role_name(name, union['area'])
		collection.update({'_id': union['_id']}, {'$set': {'uid': uid, 'name': name}})
		names.add(name)
		uid += 1
		progress_bar(uid - 1)
	db['IncID'].find_one_and_update({'_id': 'Union'}, {"$set": {'id': uid-1}}, upsert=True)

# 修改各种排行榜信息
def modify_game_rank(dst_conn):
	col_name = 'RankRole'
	col_role_name = 'Role'
	col_conn = dst_conn[col_name]
	col_role_conn = dst_conn[col_role_name]

	ranks = col_conn.find({}, {'_id'})
	count = ranks.count()
	progress_bar = get_progress_bar('modify_game_rank', count)
	idx = 1
	for rank in ranks:
		role = col_role_conn.find_one({'_id': rank['_id']}, {'name': 1})
		col_conn.update_one({'_id': rank['_id']}, {'$set': {'role.name': role['name']}})

		progress_bar(idx)
		idx += 1

# 删除石英机器人Record
def delete_craft_robot(dest, db):
	pass

# 删除竞技场机器人
def delete_arena_robot(dest, db):
	# TODO: 这个时候还没有建立索引，考虑下性能
	collection = db['ArenaRecord']
	robot_records = collection.find({'robot': {'$exists': True}}, {'_id': 1, 'role_db_id': 1})
	role_ids = [] # 机器人 role_db_id 列表
	record_ids = set([]) # 机器人 _id集合
	for record in robot_records:
		record_ids.add(record['_id'])
		role_ids.append(record['role_db_id'])

	# 清理机器人数据
	db['Role'].delete_many({'_id': {'$in': role_ids}})
	db['RoleCard'].delete_many({'role_db_id': {'$in': role_ids}})
	db['ArenaRecord'].delete_many({'robot': {'$exists': True}})
	print 'delete_arena_robot Done!'
	return record_ids


# 重建竞技场排名数据, robots 为record_id 集合
def rebuild_arena_record(dest, db, ranks, robots):
	# 获取每个原始数据库的竞技场排行榜，剔除机器人，按排名顺序
	collection = db['ArenaRecord']
	# 重建排行榜
	new_ranks = {}
	rank_start = 1
	max_length = max(map(len, [v for v in ranks.values()]))  # 竞技场排名集合不会是空的，若为空此处会报错
	progress_bar = get_progress_bar('rebuild_arena_record', max_length)
	# 排名名次穿插，剔除机器人
	keys = sorted(ranks.keys())
	for i in xrange(max_length):
		for key in keys:
			rank_data = ranks[key].get(str(i), None)
			if not rank_data:
				continue
			role_id, record_id = rank_data
			if record_id in robots:  # 不存在或者是机器人,过滤机器人
				continue
			# 不是机器人就更新
			record = collection.find_one({'_id': record_id}, {'_id': 0, 'rank_top': 1})  # 如果不更新rank_top的话比较快
			if not record:
				print('不应该，这里有出现没查询到的情况，先这样处理一下')
				print(rank_data)
				continue
			rank_top = rank_start if rank_start < record['rank_top'] else record['rank_top']  # 历史最高排名奖励保留
			collection.update_one({'_id': record_id}, {'$set': {'rank': rank_start, 'rank_top': rank_top}})
			new_ranks[str(rank_start)] = rank_data
			rank_start += 1
		progress_bar(i + 1)

	db.drop_collection('ArenaGlobal')  # 清空集合
	db['ArenaGlobal'].insert_one({
		'key': dest,
		'ranks': new_ranks,
		'rank_max': len(new_ranks),
	})
	print 'rebuild_arena_record Done!'


# 处理冒险之路
def rebuild_endless_tower_global_record(dest, db):
	collection = db['EndlessTowerGlobal']

	latest_plays = {}
	lower_fighting_plays = {}
	for data_global in collection.find():
		# 最近通关战报
		for key, val in data_global['latest_plays'].iteritems():
			latest_plays.setdefault(key, []).extend(val)
		# 最低战力通关战报
		for key, val in data_global['lower_fighting_plays'].iteritems():
			lower_fighting_plays.setdefault(key, []).extend(val)

	# 每个关卡随机取前三个
	for key in latest_plays:
		random.shuffle(latest_plays[key])
		latest_plays[key] = latest_plays[key][:3]
	for key in lower_fighting_plays:
		random.shuffle(lower_fighting_plays[key])
		lower_fighting_plays[key] = lower_fighting_plays[key][:3]

	db.drop_collection('EndlessTowerGlobal')  # 清空所有
	# 重新写入
	collection.insert_one({
		'key': dest,
		'latest_plays': latest_plays,
		'lower_fighting_plays': lower_fighting_plays,
	})
	print 'rebuild_endless_tower_global_record Done!'


# 处理世界boss
def rebuild_world_boss_global_record(dest, db):
	collection = db['WorldBossGlobal']
	data = {
		'key': dest,
		'unions': {},
		'roles': {},
		'last_level': 0,
	}
	# 一般不会在玩法期间合服，就先不改 公会和角色的name了
	# 最多就是一个显示问题，都是根据ID操作的，所以不影响逻辑，改不改name不影响逻辑
	for v in collection.find():
		data['unions'].update(v['unions'])
		data['roles'].update(v['roles'])
		if v['last_level'] > data['last_level']: # boss等级按照最高值继承
			data['last_level'] = v['last_level']

	db.drop_collection('WorldBossGlobal')  # 清空所有
	# 重新写入
	collection.insert_one(data)
	print 'rebuild_world_boss_global_record Done!'


# 处理普通石英
def rebuild_craft_record(dest, db):
	# 一般非活动期间合服，如果合服则清空重新开始
	collection = db['CraftGlobal']
	data = {
		'key': dest,
		'bet': {},  # 下注信息清空
	}
	db.drop_collection('CraftGlobal')  # 清空所有
	# 重新写入
	collection.insert_one(data)

	######################################################
	collection = db['CraftGameGlobal']
	data = collection.find_one({}, {'_id': 0})
	data['key'] = dest
	data['yesterday_top8_plays'] = {}
	data['yesterday_refresh_time'] = {}
	for data_global in collection.find():
		data['signup'].update(data_global['signup'])
	db.drop_collection('CraftGameGlobal')  # 清空所有
	# 重新写入
	collection.insert_one(data)
	print 'rebuild_craft_record Done!'


# 处理公会战 周二到周五是预选赛，周六决赛
def rebuild_union_fight_record(dest, db):
	# 如果开了，继续进行
	collection = db['UnionFightGameGlobal']
	data = collection.find_one({}, {'_id': 0})
	data['key'] = dest
	data['top8_vs_union'] = {}
	for data_global in collection.find():
		if data['time'] < data_global['time']:
			data['time'] = data_global['time']
		if data['date'] < data_global['date']:
			data['date'] = data_global['date']
		if data['last_award_time'] < data_global['last_award_time']:
			data['last_award_time'] = data_global['last_award_time']
		data['signup'].update(data_global['signup'])

	db.drop_collection('UnionFightGameGlobal')  # 清空所有
	# 重新写入
	collection.insert_one(data)

	######################################################
	collection = db['UnionFightGlobal']
	data = collection.find_one({}, {'_id': 0})
	data['key'] = dest
	data['top8_plays'] = {}
	data['round_result_max'] = 0
	data['battle_stars'] = {}
	data['final_result'] = []

	role_ranks = {}
	union_ranks = {}
	top8_vs_info_map = {}
	for data_global in collection.find():
		if data['date'] < data_global['date']:
			data['date'] = data_global['date']
		if data['time'] < data_global['time']:
			data['time'] = data_global['time']
		if data['last_award_time'] < data_global['last_award_time']:
			data['last_award_time'] = data_global['last_award_time']

		data['unions'].update(data_global['unions'])
		data['roles'].update(data_global['roles'])
		data['bet'].update(data_global['bet'])

		for key, val in data_global['role_ranks'].iteritems():
			role_ranks.setdefault(key, []).extend(val)
		for key, val in data_global['union_ranks'].iteritems():
			union_ranks.setdefault(key, []).extend(val)
		for _, val in data_global['top8_vs_info'].iteritems():
			top8_vs_info_map[val['unionid']] = val

	# 重排
	for key, val in role_ranks.iteritems():
		val.sort(key=lambda k: (int(k['point']), int(k['figure'])), reverse=True)
		for count in xrange(len(val)):
			val[count]['rank'] = count + 1
	for key, val in union_ranks.iteritems():
		val.sort(key=lambda k: (k['point'], k['level']), reverse=True)
		for count in xrange(len(val)):
			val[count]['rank'] = count + 1
	# 获取前8强公会
	top8_vs_info = {}
	rank = 1
	for union_rank in union_ranks.get(8, [])[:8]:
		top8_vs_info[rank] = top8_vs_info_map[union_rank['union_id']]
		rank += 1
	data['role_ranks'] = role_ranks
	data['union_ranks'] = union_ranks
	data['top8_vs_info'] = top8_vs_info

	db.drop_collection('UnionFightGlobal')  # 清空所有
	# 重新写入
	collection.insert_one(data)
	print 'rebuild_union_fight_record Done!'


# 处理服务器全局记录
def rebuild_server_global_record(dest, keys, db):
	collection = db['ServerGlobalRecord']
	play_ranking_names = [
		'normalbravechallengeranking',
	]
	data = {
		'key': dest,
		'half_period_keys': {}, # 存储半周期信息
		'title_roles': {}, # 称号, 废弃字段
		'title_roles_info': {}, # 新字段, 称号可以共存
		'equip_shop_refresh': 0, # 饰品抽卡商店刷新时间
		'union_roles': {},  # 公会头衔, 先清空
		'play_ranking_cross_keys': {},  # 各种玩法的排行榜
		'normal_brave_challenge': {},  # 普通勇者
	}
	for key in keys:  # 设置合服半周期信息
		data['half_period_keys'].setdefault('cross_craft', []).append(key)
		data['half_period_keys'].setdefault('cross_arena', []).append(key)
		data['half_period_keys'].setdefault('cross_fishing', []).append(key)
		data['half_period_keys'].setdefault('cross_online_fight', []).append(key)
		data['half_period_keys'].setdefault('cross_mine', []).append(key)
		data['half_period_keys'].setdefault('cross_gym', []).append(key)

	for v in collection.find():
		# 记录最新的 碎片本最后一次出现的日期
		# for key, val in v.get('frag_last_date', {}).iteritems():
		# 	if data['frag_last_date'].get(key, 0) < val:
		# 		data['frag_last_date'][key] = val
		if data['equip_shop_refresh'] < v['equip_shop_refresh']:
			data['equip_shop_refresh'] = v['equip_shop_refresh']
		if v['title_roles']:
			for titleID, titleInfo in v['title_roles'].iteritems():
				roleID, openTime = titleInfo
				data['title_roles_info'].setdefault(titleID, {})[roleID] = openTime
		if 'title_roles_info' in v and v['title_roles_info']:
			for titleID, roleInfo in v['title_roles_info'].iteritems():
				data['title_roles_info'].setdefault(titleID, {}).update(roleInfo)

		for play_ranking_name in play_ranking_names:
			if play_ranking_name not in data['play_ranking_cross_keys'] and play_ranking_name in v['play_ranking_cross_keys']:
				data['play_ranking_cross_keys'][play_ranking_name] = v['play_ranking_cross_keys'][play_ranking_name]

		if 'normal_brave_challenge' in v and not data['normal_brave_challenge'] and v['normal_brave_challenge']:
			data['normal_brave_challenge'] = v['normal_brave_challenge']

	db.drop_collection('ServerGlobalRecord')  # 清空所有
	# 重新写入
	collection.insert_one(data)
	print 'rebuild_server_global_record Done!'


# 处理卡牌战力排名
def rebuild_card_fight_global_record(dest, db):
	collection = db['CardFightGlobal']
	data = collection.find_one({}, {'_id': 0})
	data['key'] = dest
	data['cards'] = {}
	data['has_init_data'] = False  # 设置为False，在重启服务时会自动重建排行榜
	db.drop_collection('CardFightGlobal')  # 清空所有
	# 重新写入
	collection.insert_one(data)
	print 'rebuild_card_fight_global_record Done!'


# 处理本服道馆
def rebuild_gym_record(dest, keys, db):
	collection = db['GymGlobal']
	data = {
		'key': dest.replace('game', 'gym'),
		'round': 'start',
		'leader_roles': {},  # 清空荣誉馆主
		'pass_nums': {},
	}
	for v in collection.find():
		data['pass_nums'].update(v['pass_nums'])
	db.drop_collection('GymGlobal')  # 清空所有
	collection.insert_one(data)  # 重新写入

	# 处理关卡字段，因为关卡是服务器随机的，这里处理成统一的取当前合服区的第一个数据
	collection = db['GymGameGlobal']
	data = collection.find_one({'key': keys[0]}, {'_id': 0, 'gym_gates': 1})
	collection.update_many({}, {'$set': {'gym_gates': data['gym_gates']}})


MergeProc = 0


def run_proc(dest, keys):
	global MergeProc

	if MergeProc in [0, 1]:
		# 1. dump 原始数据库
		init_dir()  # 初始化备份目录,清空原有备份文件
		mongo_dump_data(keys)
		MergeProc = 2

	if MergeProc not in [0, 2]:
		raise Exception("MergeProc error: %s" % MergeProc)

	# 2. 清空已有数据， 合服中断重启的时候，先清空中断前的数据，重新开始合服
	with open_mongo(MongoDefs[dest]) as client:
		name = split_name(MongoDefs[dest])
		db = client[name]
		for col in db.list_collection_names():
			db.drop_collection(col)

	# 3. 恢复数据到目标数据库
	mongo_restore_data(dest, keys)

	# 4. 修改Role, Union数据
	with open_mongo(MongoDefs[dest]) as client:
		name = split_name(MongoDefs[dest])
		db = client[name]
		modify_role_data(db) # 修改Role数据
		modify_union_data(db) # 修改Union数据

	# 5. 全局数据处理
		# 5.1 处理冒险之路
		rebuild_endless_tower_global_record(dest, db)
		# 5.2 处理世界boss, 一般非活动期间合服
		rebuild_world_boss_global_record(dest, db)
		# 5.3 处理普通石英
		rebuild_craft_record(dest, db)
		# 5.4 处理服务器全局记录
		rebuild_server_global_record(dest, keys, db)
		# 5.5 处理卡牌战力排名
		rebuild_card_fight_global_record(dest, db)
		# 5.6 处理公会战
		rebuild_union_fight_record(dest, db)
		# 5.7 处理本服道馆
		rebuild_gym_record(dest, keys, db)
		############################# 这几个跨服直接合并就可以了，目前不需要做更多处理，项目中做了半周期处理
		# 处理跨服石英
		# 处理跨服竞技场
		# 处理跨服钓鱼
		# 处理跨服对战竞技场
		# 处理跨服道馆

	# 6. 竞技场数据处理, 特殊处理, 因为_id都一样
	# 从原始区服读取排名信息
	ranks = {}
	for key in keys:
		with open_mongo(MongoDefs[key]) as client:
			name = split_name(MongoDefs[key])
			data = client[name]['ArenaGlobal'].find_one()
			ranks[key] = data['ranks']

	with open_mongo(MongoDefs[dest]) as client:
		name = split_name(MongoDefs[dest])
		db = client[name]
		robots = delete_arena_robot(dest, db)
		# 清除战斗历史
		db['ArenaRecord'].update_many({}, {'$set': {'history': []}})
		db['CraftRecord'].update_many({}, {'$set': {'history': []}})
		db['UnionFightRoleRecord'].update_many({}, {'$set': {'history': []}})

		rebuild_arena_record(dest, db, ranks, robots)


def run(dest, keys):
	global MergeProc
	MergeProc += 1
	while True:
		try:
			run_proc(dest, keys)
			break
		except Exception as e:
			traceback.print_exc()
			print(e)
			again = False
			while True:
				if MergeProc == 1:
					r = raw_input("重新开始运行, 请确认(y/n):")
				elif MergeProc == 2:
					r = raw_input("将跳过备份重新导入, 请确认(y/n):")
				else:
					raise Exception("MergeProc error: %d" % MergeProc)
				if r == 'n' or r == 'N':
					again = False
					break
				elif r == 'y' or r == 'Y':
					again = True
					break
			if not again:
				break
