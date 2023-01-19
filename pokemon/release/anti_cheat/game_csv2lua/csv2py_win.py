#-*- coding=utf-8 -*-
# csv2py

import os
import sys

if __name__ == '__main__':

	csv2src = __import__('csv2src')
	cfg = __import__('pyservcfg_win')
	print cfg.__doc__

	try:
		os.remove(cfg.LUA_FILE_NAME)
	except Exception, e:
		pass

	if len(sys.argv) > 1:
		cfg.LANGUAGE = sys.argv[1]

	csv2src.__dict__.update(cfg.__dict__)
	csv2src.main()
