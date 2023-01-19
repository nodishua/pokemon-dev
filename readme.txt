dev_db 测试服数据库
patch client更新(nginx)
----
pokemon 服务端目录
--pokemon/crash_platform 数据上报
--deploy_dev/game_db 数据库
--pokemon/deploy_dev/supervisord.dir 业务启动配置
--pokemon/release  服务端
--pokemon_server_tool 维护工具

游戏启动方法

cd /mnt/pokemon/deploy_dev
supervisord -c supervisord.conf 
supervisorctl status  查看服务状态
supervisorctl restart all  启动所有服务
supervisorctl reload 重新加载配置
supervisorctl start gm_server  启动单个服务


测试服deploy_dev/game_db 已经导入所需要的数据库,直接启动无需再次导入,测试服对应ip为192.168.1.233

我直接用下面方法查找替换修改测试服IP
find . -type f -name "*.py"|xargs sed -i '' 's/192.168.1.233/1.1.1.1/g'
find . -type f -name "*.json"|xargs sed -i '' 's/192.168.1.233/1.1.1.1/g'



---服务端运行环境安装
apt-get install expect subversion build-essential  lib32stdc++6 gcc-multilib  g++-multilib python-dev pypy-dev gdb python2.7-dbg libcurl4-openssl-dev graphviz openssl libssl-dev swig gawk iotop lsof iftop ifstat iptraf htop dstat iotop  ltrace strace sysstat bmon nethogs silversearcher-ag libsasl2-2 sasl2-bin libsasl2-modules python-setuptools luajit curl wget unzip

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.6 main" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list
apt-get install mongodb-org=3.6.12 mongodb-org-server=3.6.12 mongodb-org-shell=3.6.12 mongodb-org-mongos=3.6.12 mongodb-org-tools=3.6.12

rm -rf /usr/lib/python2.7/dist-packages/OpenSSL
rm -rf /usr/lib/python2.7/dist-packages/pyOpenSSL-0.15.1.egg-info
pip install cython six lz4==0.8.2 numpy==1.16.0 xlrd xdot rpdb psutil fabric pycurl pycrypto M2Crypto==0.36.0 objgraph msgpack-python backports.ssl-match-hostname Markdown toro pymongo pyrasite pyopenssl ThinkingDataSdk==1.4.0
pip install tornado==4.4.2
pip install Supervisor==3.3.0
pip install cryptography==2.6

注意: debian8.11 pythone2.7 mongo3.6 ,外部服一定要做好iptebles,数据库端口不允许外部访问,最好只开放游戏端口,这样比较安全些,GM后台密码不能为简单,本测试端后台密码为admin:admin

