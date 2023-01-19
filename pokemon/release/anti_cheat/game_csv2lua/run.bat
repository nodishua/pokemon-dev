@echo off
if exist LastModifyList.txt (del LastModifyList.txt)
rem  python csv2lua_dev.py en
rem python csv2py.py
rem csv.py

csv2src.exe --input=../../config/game_dev --output=./config --language=en

rem csv.lua
pause