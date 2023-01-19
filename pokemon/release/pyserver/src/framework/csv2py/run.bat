@echo off
if exist LastModifyList.txt (del LastModifyList.txt)
python csv2lua.py
python csv2py.py
csv.py
csv.lua
pause