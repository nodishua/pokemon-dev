#-*-coding = UTF-8-*-
# CSV2LUA
# Scan SRC_PATH directory, read all CSV files, generate LUA
# CSV path name removes .csv suffixes, replace the separator to.
# Bullet \ fire.csv-> bullet.fire = {...}

import os
import sys
import shutil

if __name__ == '__main__':

	csv2src = __import__('csv2src')
	cfg = __import__('luaanticheatcfg')
	print (cfg.__doc__)

	try:
		os.remove(cfg.LUA_FILE_NAME)
	except Exception as e:
		pass

	try:
		path = os.path.dirname(cfg.LUA_FILE_NAME)
		if path:
			shutil.rmtree(path)
	except Exception as e:
		pass

	if len(sys.argv) > 1:
		cfg.LANGUAGE = sys.argv[1]

	csv2src.__dict__.update(cfg.__dict__)
	csv2src.main()
