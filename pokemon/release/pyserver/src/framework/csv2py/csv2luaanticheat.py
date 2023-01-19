#-*- coding=utf-8 -*-
# csv2lua
# 递归扫描SRC_PATH目录，读取全部csv文件，生成lua
# csv路径名去掉.csv后缀后，将分隔符替换为.，即为lua table变量名
# 如bullet\fire.csv -> bullet.fire = {...}

import os
import shutil

if __name__ == '__main__':

	csv2src = __import__('csv2src')
	cfg = __import__('luaanticheatcfg')
	print cfg.__doc__

	try:
		os.remove(cfg.LUA_FILE_NAME)
	except Exception, e:
		pass

	try:
		path = os.path.dirname(cfg.LUA_FILE_NAME)
		if path:
			shutil.rmtree(path)
	except Exception, e:
		pass

	csv2src.__dict__.update(cfg.__dict__)
	csv2src.main()
