dev_db ���Է����ݿ�
patch client����(nginx)
----
pokemon �����Ŀ¼
--pokemon/crash_platform �����ϱ�
--deploy_dev/game_db ���ݿ�
--pokemon/deploy_dev/supervisord.dir ҵ����������
--pokemon/release  �����
--pokemon_server_tool ά������

��Ϸ��������

cd /mnt/pokemon/deploy_dev
supervisord -c supervisord.conf 
supervisorctl status  �鿴����״̬
supervisorctl restart all  �������з���
supervisorctl reload ���¼�������
supervisorctl start gm_server  ������������


���Է�deploy_dev/game_db �Ѿ���������Ҫ�����ݿ�,ֱ�����������ٴε���,���Է���ӦipΪ192.168.1.233

��ֱ�������淽�������滻�޸Ĳ��Է�IP
find . -type f -name "*.py"|xargs sed -i '' 's/192.168.1.233/1.1.1.1/g'
find . -type f -name "*.json"|xargs sed -i '' 's/192.168.1.233/1.1.1.1/g'



---��������л�����װ
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

ע��: debian8.11 pythone2.7 mongo3.6 ,�ⲿ��һ��Ҫ����iptebles,���ݿ�˿ڲ������ⲿ����,���ֻ������Ϸ�˿�,�����Ƚϰ�ȫЩ,GM��̨���벻��Ϊ��,�����Զ˺�̨����Ϊadmin:admin

