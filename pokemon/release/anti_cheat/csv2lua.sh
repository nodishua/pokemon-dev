# /bin/bash

rm -f ./game_csv2lua/config/csv.lua
rm -f ./game_scripts/config/csv.lua

rm -f -r ./game_csv2lua/config/
rm -f -r ./game_scripts/config/

cd ./game_csv2lua/
python csv2luaanticheat.py $1

cd ../
cp -f -r ./game_csv2lua/config/ ./game_scripts/config/
