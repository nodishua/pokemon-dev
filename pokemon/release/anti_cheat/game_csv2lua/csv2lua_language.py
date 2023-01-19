#-*- coding=utf-8 -*-
# csv2lua
# 递归扫描SRC_PATH目录，读取全部csv文件，生成lua
# csv路径名去掉.csv后缀后，将分隔符替换为.，即为lua table变量名
# 如bullet\fire.csv -> bullet.fire = {...}

import os
import sys
import shutil


if __name__ == '__main__':
	# print makeArray('<1; xx xx! @ # $ % ^ ;  ; " 444;4 "; <51;52>;<6;<61;62;   <611;622>  ;63>>; <  ;; > ; {;;} ;; ;{ -1 =<0;1;"2"> ;2.34={a  =b} ; "-1" = {"aa"= xa ;bb= 12 }};<>>')
	# print autoMake("{1 = 222 ;'1'='333 ';aaa= 'x;';' 4' ={name=hw;date=<2014;5;20>};5={hp=100};6=<>}")

	csv2src = __import__('csv2src')
	cfg = __import__('luacfg_language')
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
	if len(sys.argv) > 1:
		cfg.LANGUAGE = sys.argv[1]

	csv2src.__dict__.update(cfg.__dict__)
	csv2src.main()
