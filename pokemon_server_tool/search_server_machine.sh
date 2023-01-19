#!/bin/bash

cd /mnt/release
out=$(svn up new_container.py)
out=$(svn up game_defines.py)
cd /mnt/server_tool/fabfile
out=$(svn up ssh_config)
out=$(svn up fabfile.py)
out=$(svn up new_game_defines.py)

cd /mnt/server_tool
python search_server_machine.py $1
