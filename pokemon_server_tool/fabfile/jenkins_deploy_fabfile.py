#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2019 TianJi Information Technology Inc.
'''

import os
import sys
import time
import pprint
import argparse

from fabric import *
from env import config
from functools import wraps
from group import MyThreadingGroup

roledefs = {
	'machines': [
		'192.168.1.62',
	],
}

ServerIDMap = {
	'tc-pokemon-en-04': ['en_31', 'en_35', 'en_39', 'en_43'],
	'tc-pokemon-en-05': ['en_32', 'en_36', 'en_40', 'en_44'],
	'tc-pokemon-en-06': ['en_33', 'en_37', 'en_41', 'en_45'],
	'tc-pokemon-en-07': ['en_34', 'en_38', 'en_42', 'en_46'],
}

CrossIDMap = {

}

Language = 'cn'
# Language = 'tw'
# Language = 'kr'
# Language = 'en'

SVN_HOST = "192.168.1.125"
GIT_HOST = "192.168.1.250"

ServerNameList = ['game_server.ini', 'pvp_server.ini', 'storage_server.ini']
CrossServerNameList = ['cross_server.ini', 'crossdb_server.ini']

SVNVersion = None
CSVVersion = None

def get_deploy_path(c):
	ret = c.run('ls -d /mnt/deploy*').stdout
	if len(str(ret).split()) != 1:
		abort("deploy dictionary can not be determinately!")
	return ret

def get_deploy_name(c):
	if 'xy' in c.original_host:
		return 'deploy_xy'
	domain = c.original_host.split('-')
	if len(domain) == 4:
		tag = domain[-2] # tc-pokemon-en-01
	else:
		tag = domain[0] # xy-pokemon-01
	return 'deploy_%s' % tag

class parallel(object):
	def __init__(self, hosts=None):
		self.hosts = hosts

	def __call__(self, func):
		@wraps(func)
		def _warp():
			group = MyThreadingGroup(*self.hosts, config=config)
			result = group.execute(func)
			return result
		return _warp

def execute(f, hosts):
	return parallel(hosts=hosts)(f)()

def immediate(func):
	def wrapper(*args, **kwargs):
		return func(*args, **kwargs)
	wrapper.__name__ = 'immediate'
	return wrapper

@immediate
def setup_sh_env(c):
	ret = c.run('''cat ~/.bashrc|grep "export LS_OPTIONS='-Sh --color=auto'"''')
	if ret.exited != 0:
		c.run('''
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LS_OPTIONS='-Sh --color=auto'" >> ~/.bashrc
echo "export GREP_OPTIONS='-n --color'" >> ~/.bashrc
echo 'eval "`dircolors`"' >> ~/.bashrc
echo "alias ls='ls $LS_OPTIONS'" >> ~/.bashrc
echo "alias ll='ls $LS_OPTIONS -l'" >> ~/.bashrc
echo "alias l='ls $LS_OPTIONS -lA'" >> ~/.bashrc
echo "alias rm='rm -i'" >> ~/.bashrc
echo "alias cp='cp -i'" >> ~/.bashrc
echo "alias mv='mv -i'" >> ~/.bashrc

echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LC_ALL=C" >> ~/.bashrc
echo "export TZ='Asia/Shanghai'" >> ~/.bashrc
		''')

	# timezone
	c.run('ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime')
	c.run('echo Asia/Shanghai > /etc/timezone')

	# coredump
	c.run('ulimit -c unlimited')
	c.run('echo "*          soft     core   unlimited" >> /etc/security/limits.conf')
	c.run('echo "*          hard     nofile   unlimited" >> /etc/security/limits.conf')
	c.run('echo 1 > /proc/sys/kernel/core_uses_pid')
	c.run('echo "/tmp/corefile-%e-%p-%t" > /proc/sys/kernel/core_pattern')

	# ipv6
	c.run('sysctl -w net.ipv6.conf.all.disable_ipv6=0')
	c.run('sysctl -w net.ipv6.conf.default.disable_ipv6=0')
	c.run('sysctl -w net.ipv6.conf.eth0.disable_ipv6=0')
	c.run('sysctl -w net.ipv6.conf.lo.disable_ipv6=0')

	c.run('apt-get update')
	c.run('apt-get install zsh -y')
	c.run('apt-get install git -y')

	ret = c.run('ls .oh-my-zsh')
	if ret.exited != 0:
		while True:
			c.put(os.path.join(os.getcwd(), 'oh-my-zsh.tar.gz'), '/root/oh-my-zsh.tar.gz')
			c.run('tar zxf oh-my-zsh.tar.gz .oh-my-zsh')
			c.run('cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc')
			break

			# ret = c.run(u'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"')
			# --no-check-certificate
			# if ret:
			# 	break

	ret = c.run(''' cat ~/.zshrc|grep 'ZSH_THEME="ys"' ''')
	if ret.exited != 0:
		c.run('sed -i "s/robbyrussell/ys/g" ~/.zshrc')
	ret = c.run(''' cat ~/.zshrc ''')
	if ret.exited == 0:
		c.run('chsh -s /bin/zsh')

@immediate
def check_disk_mem(c):
	c.run('free -h')
	c.run('fdisk -l|grep "Disk /dev"')
	c.run('df -h|grep mnt')

@immediate
def setup_disk(c):
	vdevice = 'vdb'
	# vdevice = 'sdb' # xy-game
	ret = c.run('fdisk -l|grep /dev/%s1' % vdevice)
	if ret.exited != 0:
		c.run('echo "n\np\n1\n\n\nwq\n\n"|fdisk -S 56 /dev/%s' % vdevice)
		c.run('mkfs.ext4 /dev/%s1 -F' % vdevice)
		ret = c.run('cat /etc/fstab|grep /dev/%s1' % vdevice)
		if ret.exited != 0:
			c.run("echo '/dev/%s1  /mnt ext4    defaults    0  0' >> /etc/fstab" % vdevice)
		c.run('mount -a')

@immediate
def setup_aptget(c):
	c.run('apt-get update')
	libs = (
		'expect',
		'subversion',
		'build-essential',
		'lib32stdc++6',
		'gcc-multilib',
		'g++-multilib',
		'python-dev',
		'pypy-dev',
		'gdb',
		'python2.7-dbg',
		'libcurl4-openssl-dev',
		'graphviz',
		'openssl',
		'libssl-dev',
		'swig',
		'gawk',
		'iotop',
		'lsof',
		'iftop',
		'ifstat',
		'iptraf',
		'htop',
		'dstat',
		'iotop',
		'ltrace',
		'strace',
		'sysstat',
		'bmon',
		'nethogs',
		'silversearcher-ag',
		'libsasl2-2',
		'sasl2-bin',
		'libsasl2-modules',
		'python-setuptools',
		'luajit',
		'curl',
	)
	for lib in libs:
		c.run('apt-get install %s -y' % lib)

@immediate
def setup_pip(c):
	c.put(os.path.join(os.getcwd(), 'get-pip.py'), '/root/get-pip.py')
	# c.run('curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py')
	c.run('cd ~ && python get-pip.py')
	# c.run('pip install --upgrade pip')
	# c.run('python -m pip install --upgrade setuptools')
	libs = (
		'supervisor',
		'cython',
		'six',
		('lz4', "0.8.2"),
		('numpy', "1.16.0"),
		'xlrd',
		'xdot',
		'rpdb',
		'psutil',
		'fabric', # apt-get remove python-cryptography python-cffi
		'pycurl',
		'pycrypto',
		('M2Crypto', "0.36.0"),
		'objgraph',
		'msgpack-python',
		'backports.ssl-match-hostname',
		('tornado', "5.1.1"),
		'Markdown', # toro?
		('toro', "1.0.1"),
		'pymongo',
		'pyrasite',
		'pyopenssl',
		('ThinkingDataSdk', "1.4.0"),
	)

	# AttributeError: 'module' object has no attribute 'SSL_ST_INIT'
	c.run('rm -rf /usr/lib/python2.7/dist-packages/OpenSSL')
	c.run('rm -rf /usr/lib/python2.7/dist-packages/pyOpenSSL-0.15.1.egg-info')

	for lib in libs:
		while True:
			if isinstance(lib, str):
				# -i https://pypi.tuna.tsinghua.edu.cn/simple
				cmd = 'pip install %s' % lib
			else:
				cmd = 'pip install -v %s==%s' % lib
			ret = c.run(cmd)
			if ret.exited == 0:
				break

@immediate
def setup_svn_db(c):
	deployName = get_deploy_name(c)
	# if True:
	with c.forward_remote(local_port=3690, local_host=SVN_HOST, remote_port=3690):
		svnPrefix = 'svn://localhost/svn/pokemon_src'
		with c.cd('/mnt'):
			ret = c.run('ls release')
			if ret.exited != 0:
				c.run('sed -i "s/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g" ~/.subversion/servers')
				c.run('sed -i "s/# store-passwords = no/store-passwords = yes/g" ~/.subversion/servers')
				c.run('sed -i "s/# store-passwords = no/store-passwords = yes/g" ~/.subversion/config')

				c.run('svn co %s/release --username test --password 123456' % svnPrefix)

			ret = c.run('ls %s' % deployName)
			if ret.exited != 0:
					c.run('svn co %s/trunk/deploy/%s --username test --password 123456' % (svnPrefix, deployName))

		with c.cd('/mnt/release'):
			if SVNVersion is None:
				c.run('svn up --username test --password 123456')
				if CSVVersion is not None:
					c.run('svn up -r %d %s_config_csv.py' % (CSVVersion, Language))
			else:
				c.run('svn up -r %d' % SVNVersion)
				if CSVVersion is None:
					c.run('svn up %s_config_csv.py' % Language)
				else:
					c.run('svn up -r %d %_config_csv.py' % (CSVVersion, Language))
			c.run('chmod +x bin/*')

			ret = c.run(''' cat dev_patch.py|grep "#framework.__dev__ = True" ''')
			if ret.exited != 0:
				c.run('sed -i "s/framework.__dev__/#framework.__dev__/g" dev_patch.py')
			ret = c.run(''' cat dev_patch.py|grep "framework.__language__ = '%s'" ''' % Language)
			if ret.exited != 0:
				c.run(''' sed -i "s/framework.__language__ = '.*'/framework.__language__ = '%s'/g" dev_patch.py ''' % Language)

	# if True:
	with c.forward_remote(local_port=443, local_host=GIT_HOST, remote_port=3000):
		with c.cd('/mnt/release'):
			# c.run('rm src')
			# c.run('rm -r pyserver')
			c.run('bash deploy.sh release')
		with c.cd('/mnt/release/src'):
			c.run('git pull origin master')

		with c.cd('/mnt/release/anti_cheat'):
			c.run('chmod +x agent')
			c.run('chmod +x deploy.sh')
			c.run('chmod +x csv2lua.sh')
			c.run('./deploy.sh release')
			with c.cd('game_scripts'):
				ret = c.run(''' cat anti_main.lua|grep "LOCAL_LANGUAGE = '%s'" ''' % Language)
				if ret.exited != 0:
					c.run(''' sed -i "s/LOCAL_LANGUAGE = '.*'/LOCAL_LANGUAGE = '%s'/g" anti_main.lua ''' % Language)
			ret = c.run(''' cat csv2lua.sh|grep "python csv2luaanticheat.py %s" ''' % Language)
			if ret.exited != 0:
				c.run(''' sed -i "s/python csv2luaanticheat.py .*/python csv2luaanticheat.py %s/g" csv2lua.sh ''' % Language)
			c.run('./csv2lua.sh')

@immediate
def setup_anti_cheat(c):
	with c.cd('/mnt/release/anti_cheat'):
		with c.forward_remote(local_port=443, local_host=GIT_HOST, remote_port=3000):
			c.run('chmod +x agent')
			c.run('chmod +x deploy.sh')
			c.run('chmod +x csv2lua.sh')
			c.run('./deploy.sh release')
			c.run('./csv2lua.sh %s' % Language)

@immediate
def setup_rsyslog(c):
	deployName = get_deploy_name(c)
	c.run('cp /mnt/%s/game-log-client.conf /etc/rsyslog.d/' % deployName)
	if c.run('rsyslogd -N1').exited != 0:
		print "!err"
	else:
		c.run('service rsyslog restart')

@immediate
def setup_supervisor(c):
	deployName = get_deploy_name(c)
	with c.cd('/mnt/%s/supervisord.dir' % deployName):
		with c.forward_remote(local_port=3690, local_host=SVN_HOST, remote_port=3690):
			c.run('svn up --username test --password 123456')
		# 删除多余的配置
		ret = c.run('ls *').stdout.split()
		allini = set(ret)
		serverIDs = ServerIDMap[c.original_host]
		for s in reversed(ServerNameList):
			deployNameL = ['%s_%s' % (x, s) for x in serverIDs]
			for name in deployNameL:
				allini.discard(name)
		name = '_'.join(c.original_host.split('-')[-2:] + ['anti_cheat_server.ini'])
		allini.discard(name)
		name = '_'.join(c.original_host.split('-')[-2:] + ['online_fight_forward_server.ini'])
		allini.discard(name)
		allini.discard('monitor.ini')
		if allini:
			allini = list(allini)
			while len(allini) > 100:
				c.run('rm -f %s' % ' '.join(allini[:100]))
				allini = allini[100:]
			if allini:
				c.run('rm -f %s' % ' '.join(allini))

@immediate
def setup_startserv(c):
	# ret = c.run("ps aux|grep supervisord|head -1|awk '{print $2}'").stdout.split()[0]
	# print ret
	# c.run("kill -9 %d" % int(ret))

	deployName = get_deploy_name(c)
	with c.cd('/mnt/%s' % deployName):
		c.run('supervisord')

@immediate
def test_env(c):
	ret = c.run('sysctl -a|grep "net.ipv6.conf.eth0.disable_ipv6 = 0"')
	if ret.exited != 0:
		print '!!! Err in ipv6'

	ret = c.run('cat /etc/timezone')
	if ret.stdout.strip() != 'Asia/Shanghai':
		print '!!! Err in timezone'

	ret = c.run('python -c "import datetime;print datetime.datetime.fromtimestamp(0)"')
	if ret.stdout.strip() != "1970-01-01 08:00:00":
		print '!!! Err in timezone'

	ret = c.run('python -c "import msgpack;print msgpack.Packer"')
	if ret.stdout.find('fallback') >= 0:
		print '!!! Err in msgpack'

	with c.cd('/mnt/release'):
		ret = c.run(''' cat dev_patch.py|grep "#framework.__dev__ = True" ''')
		if not ret:
			print '!!! Err in __dev__'

	with c.cd('/mnt/release'):
		ret = c.run(''' cat dev_patch.py|grep "framework.__language__" ''')

	with c.cd('/mnt/release/anti_cheat/game_scripts'):
		ret = c.run(''' cat anti_main.lua|grep "LOCAL_LANGUAGE =" ''')

@immediate
def setup_logbus(c):
	# print "test!!!!", c, type(c)
	# print c.run('hostname')
	# print c.original_host
	# c.run('pip install ThinkingDataSdk')

	with c.cd('/mnt'):
		ret = c.run('ls ta-logBus')
		if ret.exited != 0:
			c.put(os.path.join(os.getcwd(), '../logbus/ta-logBus.tar.gz'), '/mnt/ta-logBus.tar.gz')
			c.run('tar xzf ta-logBus.tar.gz')
			c.run('rm ta-logBus.tar.gz')

			with c.cd('/mnt/ta-logBus/bin'):
				c.run('chmod +x *')

	ret = c.run('ls /mnt/ta-logBus/java')
	if ret.exited != 0:
		with c.cd('/mnt/ta-logBus/bin'):
			c.run('./check_java')
			c.run('./install_logbus_jdk.sh')

	ret = c.run('ls /mnt/logbus_data')
	if ret.exited != 0:
		c.run('mkdir /mnt/logbus_data')

	filename = 'logBus.conf'
	if Language != "cn":
		filename = 'logBus_%s.conf' % Language
	c.put(os.path.join(os.getcwd(), '../logbus/%s' % filename), '/mnt/ta-logBus/conf/logBus.conf')

	# start logbus
	with c.cd('/mnt/ta-logBus/bin'):
		c.run('./logbus env')
		c.run('./logbus start')

def _test(c):
	print '!!!', c
	ret = c.run('''python -c "import uuid;print uuid.UUID(int=uuid.getnode()).hex[-12:];" ''')
	return ret.stdout.strip()

def test(hosts):
	result = execute(_test, hosts)
	print "=" * 10
	for c in sorted(result.keys(), key=lambda x: x.original_host):
		k = c.original_host
		v = result[c]
		if v != 0:
			print k, v

@immediate
def all_setup(c):
	setup_sh_env(c)
	setup_disk(c)
	setup_aptget(c)
	setup_pip(c)
	setup_svn_db(c)
	setup_anti_cheat(c)
	setup_rsyslog(c)
	setup_supervisor(c)
	setup_startserv(c)

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description="")
	parser.add_argument('--language', type=str, default="cn", help="language")
	parser.add_argument('--hosts', type=str, default="", help="hosts")
	# parser.add_argument('--methods', type=str, default="", help="run methods")
	parser.add_argument('--method', type=str, default="", help="run method")
	args = parser.parse_args()

	print args

	global Language
	Language = args.language

	hosts = args.hosts.split()
	if not hosts:
		hosts = roledefs["machines"]
	method = args.method

	mod = sys.modules[__name__]
	func = getattr(mod, method)
	if func.__name__ == 'immediate':
		execute(func, hosts)
	else:
		func(hosts)



