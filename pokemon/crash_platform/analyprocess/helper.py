 # -*- coding: utf-8 -*-
"""
对.so文件和.dmp文件进行处理解析的逻辑
"""
from __future__ import absolute_import

import os
import re
import json

from settings import BASEDIR, DUMP_PATH, DUMP_FILE_NAME, SYMBOLS_PATH, UPLOAD_FILE_NAME, APP_DEBUG, SECRET_ID, SECRET_KEY
from util import call_subprocess, is_exist_file

# 生成一些必要的目录
def prepare():
	if not is_exist_file("breakpad", BASEDIR):
		raise Exception, "Not breakpad tools?"

	if not is_exist_file(UPLOAD_FILE_NAME, BASEDIR):
		cmd = "mkdir %s"% UPLOAD_FILE_NAME
		call_subprocess(cmd, BASEDIR)

	if not is_exist_file(APP_DEBUG, BASEDIR):
		cmd = "mkdir %s"% APP_DEBUG
		call_subprocess(cmd, BASEDIR)

	if not is_exist_file(DUMP_FILE_NAME, BASEDIR):
		cmd = "mkdir %s"% DUMP_FILE_NAME
		call_subprocess(cmd, BASEDIR)
		cmd = "mkdir symbols"
		call_subprocess(cmd, DUMP_PATH)

# 生成.sym符号标记文件
def generate_symbol_file(path_name, file_name, already=False): # path_name：上传.so文件路径，file_name：上传.so文件名
	if already and file_name.endswith(".sym"):
		file_name = file_name[:-4]

	# 创建.so文件夹
	if not is_exist_file(file_name, SYMBOLS_PATH):
		cmd = "mkdir %s"% file_name
		call_subprocess(cmd, SYMBOLS_PATH)

	# 生成.sym符号文件
	if not already:
		cwd = os.path.join(BASEDIR, "breakpad/tools/linux/binaries/")
		cmd = "./dump_syms %s"% path_name
		result = call_subprocess(cmd, cwd)
		if not result:
			return (None, "unable-no result")
	else:
		result = path_name

	# 获取.sym第一行创建文件夹
	ret = re.search(r".+\n", result)
	if not ret:
		return (None, "unable-no line")
	try:
		nums = ret.group().split()[3].strip()
	except IndexError:
		return (None, "unable-no symbol nums")

	cwd = os.path.join(SYMBOLS_PATH, "%s/"% file_name)
	if not is_exist_file(nums, cwd):
		cmd = "mkdir %s" % nums
		call_subprocess(cmd, cwd)

	# 存入.sym文件
	nameSym = file_name + ".sym"
	path = os.path.join(SYMBOLS_PATH, "%s/%s/%s"% (file_name, nums, nameSym))
	with open(path, "wb") as f:
		f.write(result)
	return (True, nums)

# 将dmp文件写入硬盘,返回路径
def write_dmp_file(file_info):
	file_path = str(file_info["id"]) + "." + "dmp"
	dirName = str(file_info["report_time"].date())
	if not is_exist_file(dirName, DUMP_PATH):
		cmd = "mkdir %s"% dirName
		call_subprocess(cmd, DUMP_PATH)

	file_path = os.path.join(DUMP_PATH, os.path.join(dirName, file_path))
	with open(file_path, "wb") as f:
		f.write(file_info["file_content"])

	file_info["file_content"] = None
	return file_path

# 解析dump生成stack
def analysis_dmp_file(file_info): # path_name：dump路径
	path_name = file_info.file_path

	sys = file_info.phone_sys + file_info.phone_name + file_info.platform
	sys = sys.lower()
	if "ios" in sys:
		# assert file_info.game_name != None, "%s game_name is None"% file_info.id
		# symbol = file_info.package_name
		symbol = None
	elif "android" in sys:
		symbol = "libcocos2dlua.so"
	else:
		symbol = None

	tool_path = os.path.join(BASEDIR, "breakpad/tools/linux/binaries/minidump_stackwalk") # 工具路径 /.../minidump_stackwalk
	path_list = path_name.split("/")
	path_name = os.path.join(path_list[-2], path_list[-1]) # 20180904/xxxx.dmp

	cmd = "%s %s ./symbols" % (tool_path, path_name)
	result = call_subprocess(cmd, DUMP_PATH) # 解析出来的结果stack, 便于阅读的类型
	cmd = "%s -m %s ./symbols" % (tool_path, path_name)
	ret = call_subprocess(cmd, DUMP_PATH) # 解析出来的结果stack, “|”分割好的结果，便于分析
	if not ret or not result: # 没有解析出结果
		return (None, "unable-no result")

	# 查找解析所使用的symbols字符串
	# Module部分每一行都是由7个“|”分割开来的，符号文件字符串在第4个|后
	# Module|pushtest||pushtest|75A686FAD5B33AB3AD91A99F61FA688D0|0x1007e4000|0x1017e3fff|1
	if symbol:
		s = "Module|" + symbol
		n = ret.find(s)
		symLine = re.search(r"Module\|.+\n", ret[n:])
		if not symLine:
			return (None, "unable-no find symbols")
		symNum = symLine.group().split("|")[4].strip()
	else:
		symNum = None

	# 取出堆栈最上面的报错行，作为标记
	# 0|0|pushtest|AppDelegate::applicationDidFinishLaunching()|/Users/mc/Desktop/pokemon/trunk/client/LuaGameFramework/MyLuaGame/frameworks/runtime-src/Classes/AppDelegate.cpp|165|0x4
	# \d+\|\d+\|.+\|.+\|.*\|.*\|.*\n
	errLine_ret = re.search(r"\d+\|\d+\|.+\|.+\|.*\|.*\|.*\n", ret)
	if not errLine_ret: # 匹配不到相关的报错行，说明解析不正确
		return (None, "unable-no find error line")
	errLine = errLine_ret.group().split(r"|") # Thread部分每一行都是由6个“|”分割开来的
	feature = errLine[3]
	ident = errLine[3].replace(" ", "")
	threadID = errLine[0]

	# 匹配出错线程中的错误行
	regex = re.compile("%s\|\d+\|.+\|.+\|.*\|.*\|.*\n"% threadID)
	stringL = regex.findall(ret)
	error = []
	for i in stringL:
		item = i.split("|")
		error.append(item[3].replace(" ", ""))

	return (result, symNum, feature, ident, error)


# 机器翻译
def translate(text, language):
	"""
	install: pip install -i https://mirrors.tencent.com/pypi/simple/ --upgrade tencentcloud-sdk-python
	doc: https://cloud.tencent.com/document/product/551/15619#2.-.E8.BE.93.E5.85.A5.E5.8F.82.E6.95.B0
	"""
	import json
	from tencentcloud.common import credential
	from tencentcloud.common.profile.client_profile import ClientProfile
	from tencentcloud.common.profile.http_profile import HttpProfile
	from tencentcloud.common.exception.tencent_cloud_sdk_exception import TencentCloudSDKException
	from tencentcloud.tmt.v20180321 import tmt_client, models
	lans = {
		'kr': 'ko',  # 韩语
	}
	if language not in lans or len(text) > 2000:
		return ''

	try:
		cred = credential.Credential(SECRET_ID, SECRET_KEY)
		httpProfile = HttpProfile()
		httpProfile.endpoint = "tmt.tencentcloudapi.com"

		clientProfile = ClientProfile()
		clientProfile.httpProfile = httpProfile
		client = tmt_client.TmtClient(cred, "ap-shanghai", clientProfile)

		req = models.TextTranslateRequest()
		params = {
			"SourceText": text,
			"Source": lans[language],
			"Target": "zh",
			"ProjectId": 0,
		}
		req.from_json_string(json.dumps(params))

		resp = client.TextTranslate(req)
		result = json.loads(resp.to_json_string())
		return result['TargetText']
	except TencentCloudSDKException as err:
		print err
		return ''
