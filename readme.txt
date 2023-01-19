dev_db test server database
patch client update (nginx)
----
pokemon server directory
--pokemon/crash_platform data reporting
--deploy_dev/game_db database
--pokemon/deploy_dev/supervisord.dir business startup configuration
--pokemon/release server
--pokemon_server_tool maintenance tool

Game start method

cd /mnt/pokemon/deploy_dev
supervisord -c supervisord.conf
supervisorctl status View service status
supervisorctl restart all starts all services
supervisorctl reload reload configuration
supervisorctl start gm_server starts a single service


The test server deploy_dev/game_db has already imported the required database, and it can be started directly without importing again. The corresponding ip of the test server is 192.168.1.233

I directly use the following method to find, replace and modify the IP of the test server
find . -type f -name "*.py"|xargs sed -i '' 's/192.168.1.233/1.1.1.1/g'
find . -type f -name "*.json"|xargs sed -i '' 's/192.168.1.233/1.1.1.1/g'



---Server operating environment installation
apt-get install expect subversion build-essential lib32stdc++6 gcc-multilib g++-multilib python-dev pypy-dev gdb python2.7-dbg libcurl4-openssl-dev graphviz openssl libssl-dev swig gawk iotop lsof iftop ifstat iptraf htop dstat iotop ltrace strace sysstat bmon nethogs silversearcher-ag libsasl2-2 sasl2-bin libsasl2-modules python-setuptools luajit curl wget unzip

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.6 main" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list
apt-get install mongodb-org=3.6.12 mongodb-org-server=3.6.12 mongodb-org-shell=3.6.12 mongodb-org-mongos=3.6.12 mongodb-org-tools=3.6.12

rm -rf /usr/lib/python2.7/dist-packages/OpenSSL
rm -rf /usr/lib/python2.7/dist-packages/pyOpenSSL-0.15.1.egg-info
pip install cython six lz4==0.8.2 numpy==1.16.0 xlrd xdot rpdb psutil fabric pycurl pycrypto M2Crypto==0.36.0 objgraph msgpack-python backports.ssl-match-hostname Markdown toro pymongo pyrasite pyopenssl ThinkingDataSdk==1.4. 0
pip install tornado==4.4.2
pip install Supervisor==3.3.0
pip install cryptography==2.6

Note: debian8.11 pythone2.7 mongo3.6, the external server must do iptebles, the database port does not allow external access, it is better to only open the game port, it is safer, the GM background password cannot be simple, the background of this test terminal The password is admin:admin
