#!/bin/bash

domain="192.168.1.235"
protocol="https"
if [ "$1" == release ]; then
	domain="localhost:3000"
fi
url=${protocol}://robot:robot@${domain}/tjgame/pokemon_server.git
echo $url

if [ -d "pyserver" ]; then
	echo "already pyserver!"
else
	echo "no pyserver!"
	mkdir pyserver
	cd pyserver
	git init
	git config --global http.sslVerify false
	git config core.sparsecheckout true
	git remote add -f origin $url
	echo "/src/" >> .git/info/sparse-checkout
	git pull origin master
	cd ..
	ln -s pyserver/src
fi
