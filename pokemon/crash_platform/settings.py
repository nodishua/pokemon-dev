# -*- coding: utf-8 -*-

import os
import base64, uuid


BASEDIR = os.path.dirname(__file__)

UPLOAD_FILE_NAME = "_file_upload" # 上传.so存放文件夹名

DUMP_FILE_NAME = "_dump_analysis" # 存放dump以及symbols文件夹名

APP_DEBUG = "_app_debug" # 存放传递过来的玩家运行日志

UPLOAD_PATH = os.path.join(BASEDIR, UPLOAD_FILE_NAME)

DUMP_PATH = os.path.join(BASEDIR, DUMP_FILE_NAME)

APP_DEBUG_PATH = os.path.join(BASEDIR, APP_DEBUG)

SYMBOLS_PATH = os.path.join(DUMP_PATH, "symbols") # 存放符号文件的文件夹

STATICFILES_DIR = os.path.join(BASEDIR, "statics")

TEMPLATES_DIR = os.path.join(BASEDIR, "templates")

COOKIES_KEY = "crash_web_name"
COOKIES_TIME = 60*60*12 # cookies超时时间s
COOKIES_SECRET = base64.b64encode(uuid.uuid4().bytes)

settings = dict(
    template_path = TEMPLATES_DIR,
    static_path = STATICFILES_DIR,
    static_url_prefix = "/statics/", # 设置静态路径头部
    xsrf_cookies = False,
    cookie_secret = COOKIES_SECRET,
    debug = False,
    # log_function = logFunc
)

# mongo数据库配置
# MONGODB_CONFIG = {
#     'host': '127.0.0.1',
#     'port': 27030,
#     'db_name': 'crash_platform',
# }

# 腾讯云
SECRET_ID = "AKIDpLglGHfbw3wa1CapGRN2WkjcFp9Mf3av"
SECRET_KEY = "MWP2wb3GJ8gyGKCnZDk9J7h26vpTxJPy"
