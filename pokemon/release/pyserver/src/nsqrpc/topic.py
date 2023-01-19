# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

# // NSQ 定义
# // 1. 全局型服务
# // REQ:
# //   Topic = MethodName
# //   Channel = "global"
# //   Host one/cluster
# //   1:1:N
# // RESP:
# //   -> 2
# // 比如:
# //   newBattlePlay game -> agent manager -> agent -> game
# //
# // 2. RPC型服务
# // REQ:
# //   Topic = [REQ|RESP]-ServiceID
# //   Channel = "rpc"
# //   Host one
# //   1:1:1
# // RESP:
# //   -> 2
# // 比如:
# //   getPvPRecord game -> pvp -> game
# //
# // 3. 通知型服务
# // NTF:
# //   Topic = MethodName
# //   Channel = ServiceID
# //   Host many
# //   1:N:Method
# // 比如:
# //   log -> gmweb
# //       -> logarchive
# //
# // 1,2型服务均有RESP回包
# // 3型服务没有，即使有client端也无法处理多种不同数据的回包

GlobalServiceChannel = "global"
RPCServiceChannel = "rpc"
ServiceRespChannel = "0global_1rpc"

GLOBAL = 0
RPC = 1
NOTIFY = 2

def ClientTopic(type, serviceID, method):
	if type == GLOBAL or type == NOTIFY:
		return method
	elif type == RPC:
		return 'REQ-%s' % serviceID

def NotifyTopic(method):
	return method

def ResponseTopic(key):
	return 'RESP-%s' % key

def RequestTopicAndChannel(type, serviceID, method):
	if type == GLOBAL:
		return method, GlobalServiceChannel
	elif type == RPC:
		return 'REQ-%s' % serviceID, RPCServiceChannel
	elif type == NOTIFY:
		return method, serviceID
