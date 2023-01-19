#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

import re
import signal
import functools
from bson.binary import Binary
from pymongo.errors import DocumentTooLarge

from defines import ServerDefs
from object.mongo import Client as MongoDB
from object.scheme import *
from .helper import *
from .object import DBCache, LRUCache

import tornado.ioloop
from tornado.log import access_log as logger


class Server(object):
	capacity_limit = 30

	def __init__(self, name, q):
		self.name = name
		self._q = q
		self.cfg = ServerDefs[name]

		self.mongo = self.setupMongo()

		self.ExcRecordDB = DBCache(ExcRecord)
		self.ExcStatisticDB = LRUCache(ExcStatistic)

		self.cursor = 0
		self.shutdown = False
		self.running = False

		# ioloop
		self.ioloop = tornado.ioloop.IOLoop()
		self.ioloop.make_current()

		# 定时器
		self.DBTimer = tornado.ioloop.PeriodicCallback(self.saveToDB, 60*1000)
		self.HandleTimer = tornado.ioloop.PeriodicCallback(self.handle, 3*1000)
		# self.SymbolHandleTimer = tornado.ioloop.PeriodicCallback(functools.partial(self.handleSymbol,
		# 	self.mongo.DBClient, {"status": False}), 10*1000)

		signal.signal(signal.SIGINT, lambda sig, frame: self.stop())
		signal.signal(signal.SIGTERM, lambda sig, frame: self.stop())

	def setupMongo(self):
		cfg = self.cfg["mongodb"]
		mongo = MongoDB(cfg["host"], cfg["port"],
			cfg["dbname"], cfg["username"], cfg["password"])

		Statistics.init(mongo.DBClient)
		Account.init(mongo.DBClient)
		SymbolFile.init(mongo.DBClient)
		DmpRecord.init(mongo.DBClient)
		DmpStatistic.init(mongo.DBClient)
		ExcRecord.init(mongo.DBClient)
		ExcStatistic.init(mongo.DBClient)
		return mongo

	@staticmethod
	def handleDmp(client, query):
		"""
		处理数据中未处理的dmp文件，生成stack结果，将结果存入数据库
		"""
		data_cursor = DmpRecord.find(client, query)

		for file_info in data_cursor:
			if not file_info["status"]:
				file_info["file_path"] = write_dmp_file(file_info)

			analysisData = analysis_dmp_file(file_info)
			if not analysisData[0]:
				logger.warning("Dump %d Analysis Fail: %s"% (file_info.id, analysisData[1]))
				file_info["status"] = analysisData[1]
				DmpRecord.update(client, {"_id": file_info.pop("_id")}, {"$set": file_info})
				return False

			result, symbolNum, feature, ident, stack_error = analysisData
			if len(ident) > 50:
				ident = ident[:50]

			file_info["symbol_nums"] = symbolNum
			file_info["stack_result"] = Binary(result)
			file_info["stack_ident"] = ident
			file_info["feature"] = feature
			file_info["stack_error"] = stack_error

			file_info["stack_ident"] = Server.classifyDmp(client, file_info)
			file_info["status"] = True

			# DocumentTooLarge: 'update' command document too large
			did = file_info.pop("_id")
			try:
				DmpRecord.update(client, {"_id": did}, {"$set": file_info})
			except DocumentTooLarge:
				logger.warning("Dump too large")
				file_info["stack_result"] = "too large"
				DmpRecord.update(client, {"_id": did}, {"$set": file_info})

			logger.info("dmp %d generate stack result Success"% file_info["id"])
			return True

	@staticmethod
	def classifyDmp(client, file_info, more=5):
		"""
		分类处理每个dmp
		"""
		ident = file_info["stack_ident"]
		stack_error = file_info["stack_error"]
		phone_sdk = file_info["device_info"].get("sdk", "unknown").replace('.', '_')

		updateData = {
			"$addToSet": {
				"record_id": file_info["id"],
				"imei": file_info["imei"],
				"game_account": file_info["server_role"],
				"report_version": file_info["version"],
			},
			"$inc": {
				"phone_name." + file_info["phone_name"]: 1,
				# mongo document not point
				"phone_sys." + file_info["phone_sys"].replace('.', '_'): 1,
				"phone_sdk." + phone_sdk: 1,
			},
			"$set": {
				"lasttime": file_info["report_time"],
			}
		}
		if file_info["status"] != True:
			updateData["$inc"]["count"] = 1

		ret = DmpStatistic.find_one(client, {"ident": ident})
		# if ret:
		# 	for i in range(more):
		# 		try:
		# 			err = stack_error[i]
		# 			err2 = ret["ident_more"][i]
		# 		except IndexError:
		# 			if len(stack_error) > len(ret["ident_more"]):
		# 				ident = stack_error[i]
		# 				break
		# 			elif len(stack_error) < len(ret["ident_more"]):
		# 				ident = stack_error[i-1]
		# 				break
		# 			else:
		# 				DmpStatistic.update(client, {"_id": ret["_id"]}, updateData)
		# 				return ident
		# 		if err != err2:
		# 			ident = err
		# 			break

		# ret = DmpStatistic.find_one(client, {"ident": ident})
		if ret:
			DmpStatistic.update(client, {"_id": ret["_id"]}, updateData)
			return ident

		data = dict(
				ident = ident,
				feature = file_info["feature"],
				ident_more = stack_error,
				record_id = [file_info["id"],],
				imei = [file_info["imei"],],
				game_account = [file_info["server_role"],],
				phone_name = {file_info["phone_name"]: 1,},
				phone_sys = {file_info["phone_sys"].replace('.', '_'): 1,},
				phone_sdk = {phone_sdk: 1,},
				firsttime = file_info["report_time"],
				lasttime = file_info["report_time"],
				count = 1,
				report_version = [file_info["version"],],
			)
		DmpStatistic.insert_one(client, data)
		return ident

	@staticmethod
	def handleSymbol(client, query):
		"""
		处理数据库中未处理的.so文件，并生成符号标记文档，update数据库信息
		"""
		data_cursor = SymbolFile.find(client, query)

		for file_info in data_cursor:
			if file_info["platform"] == "ios":
				# ios上传的sym只能在ios平台解
				continue
			_id = file_info.pop("_id")
			ret, data = generate_symbol_file(file_info["path"], file_info["name"])
			if ret:
				file_info["symbol_nums"] = data
				file_info["status"] = True
				SymbolFile.update(client, {"_id": _id}, {"$set": file_info})
				logger.info(".so %s generate symbol Success"% file_info["id"])
				continue
			file_info["status"] = data
			SymbolFile.update(client, {"_id": _id}, {"$set": file_info})
			logger.warning(".so %s generate symbol Fail !!!"% file_info["id"])

	def handleException(self):
		query = {"$and": [{"id": {"$gt": self.cursor}}, {"status": False}]} if self.cursor else {"status": False}
		data_cursor = ExcRecord.find(self.mongo.DBClient, query)

		for data in data_cursor:
			record = self.ExcRecordDB.set(data.id, data)
			# mongo document not point
			phone_sys = record.phone_sys.replace('.', '_')
			phone_sdk = record.device_info.get("sdk", "unknown").replace('.', '_')

			# 保存当前DBID
			self.cursor = max(record.id, self.cursor)

			# 提取stack首行
			firstLine = re.split(r"\n", record.stack)[0]
			identSpec = re.sub(r":\d+:", "", firstLine)

			ident = re.sub(r"\[\d+\]", "", identSpec, 1)
			ident = re.sub(r'\b0x[0-9a-fA-F]+\b', "", ident)
			ident = re.sub(r'\b[0-9]+\b', "", ident)
			ident = ident.replace(" ", "")

			# mongodb创建了索引的字段，其值不能超过1024个字节，否则插入时mongo会报错 key too large.....
			str_size = len(ident.encode("utf-8"))
			while str_size > 1000:
				raw_str_len = len(ident)
				ident = ident[:raw_str_len/2]
				str_size = len(ident.encode("utf-8"))

			# 更新DB字段
			record.feature = firstLine
			record.stack_ident = ident
			record.status = True

			record2 = self.ExcStatisticDB.get(ident)
			if not record2:
				try:
					statData = ExcStatistic.find_one(self.mongo.DBClient, {"ident": ident})
				except Exception as e:
					print e
					logger.info("New Exception %s Fail"% data.id)

				if not statData:
					statisticInfo = dict(
							ident = ident,
							feature = identSpec,
							record_id = [record.id,],
							imei = [record.imei,],
							game_account = [record.server_role,],
							phone_name = {record.phone_name: 1,},
							phone_sys = {phone_sys: 1,},
							phone_sdk = {phone_sdk: 1},
							count = 1,
							firsttime = record.report_time,
							lasttime = record.report_time,
							report_version = [record.version,]
						)

					ExcStatistic.insert_one(self.mongo.DBClient, statisticInfo)
					logger.info("Exception %s processed success"% record.id)
					return

				record2 = self.ExcStatisticDB.set(statData.ident, statData)

			# 更新DB字段
			if record.version not in record2.report_version:
				record2.report_version.append(record.version)

			if record.id not in record2.record_id:
				record2.record_id.append(record.id)

			if record.imei not in record2.imei:
				record2.imei.append(record.imei)

			if record.server_role not in record2.game_account:
				record2.game_account.append(record.server_role)

			if record.phone_name not in record2.phone_name:
				record2.phone_name[record.phone_name] = 1
			else:
				record2.phone_name[record.phone_name] += 1

			if phone_sys not in record2.phone_sys:
				record2.phone_sys[phone_sys] = 1
			else:
				record2.phone_sys[phone_sys] += 1

			if phone_sdk not in record2.phone_sdk:
				record2.phone_sdk[phone_sdk] = 1
			else:
				record2.phone_sdk[phone_sdk] += 1

			record2.count += 1
			record2.lasttime = record.report_time
			logger.info("Exception %s processed success"% record.id)

		# 检查ExcRecordDB缓存的数量
		if self.ExcRecordDB.length > self.capacity_limit:
			self.saveToDB()

	def saveToDB(self):
		self.ExcStatisticDB.saveToDB(self.mongo.DBClient)
		self.ExcRecordDB.saveToDB(self.mongo.DBClient)
		self.ExcRecordDB.clear()
		# 重置self.cursor,因为，实际测试中，id有可能会出现跳过
		# 导致有写exception一直没有被处理到，所以这里置为0，进行一次重新检测
		self.cursor = 0

	def stop(self):
		if self.shutdown:
			logger.info("%s has been stopped"% self.name)
			return
		self.shutdown = True

		self.HandleTimer.stop()
		# self.SymbolHandleTimer.stop()
		self.DBTimer.stop()
		self.saveToDB()

		self.handle()
		self.saveToDB()

		self.ioloop.stop()
		self.mongo.close()

		logger.info("the server is stopped")

	def start(self):
		if self.running:
			logger.info("%s already start"% self.name)
			return
		self.running = True

		prepare()

		# self.SymbolHandleTimer.start()
		self.HandleTimer.start()
		self.DBTimer.start()

		logger.info("%s start"% self.name)
		self.ioloop.start()

	def handle(self):
		if self._q.full():
			self.stop()

		self.handleException()
		self.handleDmp(self.mongo.DBClient, {"status": False})
		# self.handleSymbol(self.mongo.DBClient, {"status": False})


if __name__ == "__main__":
	tornado.options.define("name", default="crash_platform", help="server name", type=str)
	tornado.options.parse_command_line()
	cfg = ServerDefs[tornado.options.options.name]
	fileServer = Server(cfg)
	fileServer.start()
