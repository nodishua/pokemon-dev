#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# machine_status.py  获取本机资源使用信息、进程状态和连接情况
# created by vince67 (nuovince@gmail.com)
# May 2014

import sys
import os
import psutil as ps                       # psutil库 需预先安装
import time
import socket
import uuid
import commands
import re
import platform


class MachineStatus(object):
  
	#   初始化
	def __init__(self):
		self.MAC = None
		self.IP = None
		self.cpu = {}
		self.mem = {}
		self.process = {}
		self.network = {}
		self.status = []                    #  [cpu使用率， 内存使用率， 进程数目， established连接数]
		self.get_init_info()
		self.get_status_info()

	#  数据收集
	def get_init_info(self):
		self.cpu = {'cores': 0,            #  cpu逻辑核数
					'percent': 0,          #  cpu使用率
					'system_time': 0,      #  内核态系统时间
					'user_time': 0,        #  用户态时间
					'idle_time': 0,        #  空闲时间
					'nice_time': 0,        #  nice时间 (花费在调整进程优先级上的时间)
					'softirq': 0,          #  软件中断时间
					'irq': 0,              #  中断时间
					'iowait': 0}           #  IO等待时间
		self.mem = {'percent': 0,
					'total': 0,
					'vailable': 0,
					'used': 0,
					'free': 0,
					'active': 0}
		self.process = {'count': 0,        #  进程数目
						'pids': 0}         #  进程识别号
		self.network = {'count': 0,        #  连接总数
						'established': 0}  #  established连接数
		self.status = [0, 0, 0, 0]          #  cpu使用率，内存使用率， 进程数， established连接数
		self.py = {}
		self.os = {}
		self.pid = {}
		self.get_os_info()
		self.get_py_info()
		self.get_mac_address()
		self.get_ip_address()

	#  获取状态列表
	def get_status_info(self):
		self.get_cpu_info()
		self.get_mem_info()
		self.get_process_info()
		self.get_cur_process_info()
		self.get_network_info()

		self.status[0] = self.cpu['percent']
		self.status[1] = self.mem['percent']
		self.status[2] = self.process['count']
		self.status[3] = self.network['established']

	#  获取mac
	def get_mac_address(self):
		mac = uuid.UUID(int=uuid.getnode()).hex[-12:]
		self.MAC = ":".join([mac[e: e+2] for e in range(0, 11, 2)])
		return self.MAC

	#  获取ip
	def get_ip_address(self):
		tempSock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
		tempSock.connect(('8.8.8.8', 80))
		addr = tempSock.getsockname()[0]
		tempSock.close()
		self.IP = addr
		return self.IP

	# 获得python信息
	def get_py_info(self):
		import struct
		self.py['version'] = sys.version
		self.py['maxint'] = sys.maxint
		self.py['pointer_bits'] = struct.calcsize("P") * 8
		return self.py

	# 获得os信息
	def get_os_info(self):
		self.os['platform'] = platform.platform()   #获取操作系统名称及版本号，'Windows-7-6.1.7601-SP1'
		self.os['version'] = platform.version()    #获取操作系统版本号，'6.1.7601'
		self.os['architecture'] = platform.architecture()   #获取操作系统的位数，('32bit', 'WindowsPE')
		self.os['machine'] = platform.machine()    #计算机类型，'x86'
		self.os['node'] = platform.node()       #计算机的网络名称，'hongjie-PC'
		self.os['processor'] = platform.processor()  #计算机处理器信息，'x86 Family 16 Model 6 Stepping 3, AuthenticAMD'
		# self.os['uname'] = platform.uname()      #包含上面所有的信息汇总，uname_result(system='Windows', node='hongjie-PC', release='7', version='6.1.7601', machine='x86', processor='x86 Family 16 Model 6 Stepping 3, AuthenticAMD')
		return self.os

	#  获得cpu信息
	def get_cpu_info(self):
		self.cpu['cores'] = ps.cpu_count()
		# self.cpu['percent'] = ps.cpu_percent(interval=2)
		self.cpu['percent'] = ps.cpu_percent()
		cpu_times = ps.cpu_times()
		self.cpu['system_time'] = cpu_times.system
		self.cpu['user_time'] = cpu_times.user
		self.cpu['idle_time'] = cpu_times.idle
		if hasattr(cpu_times, 'nice'):
			self.cpu['nice_time'] = cpu_times.nice
			self.cpu['softirq'] = cpu_times.softirq
			self.cpu['irq'] = cpu_times.irq
			self.cpu['iowait'] = cpu_times.iowait
		return self.cpu

	#  获得memory信息
	def get_mem_info(self):
		mem_info = ps.virtual_memory()
		self.mem['percent'] = mem_info.percent
		self.mem['total'] = mem_info.total
		self.mem['vailable'] = mem_info.available
		self.mem['used'] = mem_info.used
		self.mem['free'] = mem_info.free
		if hasattr(mem_info, 'active'):
			self.mem['active'] = mem_info.active
		return self.mem

	#  获取进程信息
	def get_process_info(self):
		pids = ps.pids()
		self.process['pids'] = pids
		self.process['count'] = len(pids)
		return self.process

	#  获取网络数据
	def get_network_info(self):
		conns = ps.net_connections()
		self.network['count'] = len(conns)
		for conn in conns:
			status = conn.status.lower()
			self.network[status] = 1 + self.network.get(status, 0)
		return self.network

	#  获取当前进程信息
	def get_cur_process_info(self):
		pid = os.getpid()
		p = ps.Process(pid=pid)
		# res = commands.getstatusoutput('ps aux|grep '+str(pid))[1].split('\n')[0]
		# p = re.compile(r'\s+')
		# l = p.split(res)
		# self.pid = {
		# 	'user': l[0],
		# 	'pid': l[1],
		# 	'cpu': l[2],
		# 	'mem': l[3],
		# 	'vsz': l[4],
		# 	'rss': l[5],
		# 	'start_time': l[6],
		# }
		self.pid = p.as_dict(attrs=['cmdline', 'status', 'cwd', 'exe', 'memory_info', 'memory_percent', 'num_fds', 'num_threads', 'nice'])
		pcpu_times = p.cpu_times()
		p_mem = self.pid.pop('memory_info')
		self.pid.update({
			'percent': p.cpu_percent(),
			'system_time': pcpu_times.system,
			'user_time': pcpu_times.user,
			'pid': p.pid,
			'vms': p_mem.vms,
			'rss': p_mem.rss,
		})
		return self.pid

	def as_dict(self):
		return {
			'ip': self.IP,
			'mac': self.MAC,
			# 'cpu': self.cpu,
			# 'mem': self.mem,
			# 'network': self.network,
			'process': self.pid,
			'os': self.os,
			'py': self.py,
		}

if __name__ == '__main__':
	import pprint
	MS = MachineStatus()
	print MS.IP, '\n', MS.MAC, '\n', MS.cpu, '\n', MS.mem, '\n', MS.status, '\n', MS.network
	pprint.pprint(MS.pid)
