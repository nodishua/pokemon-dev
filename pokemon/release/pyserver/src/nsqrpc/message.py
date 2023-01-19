# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

import msgpack

REQUEST = 0
RESPONSE = 1
NOTIFY = 2

def NoSyncIDGenerator():
	counter = 1
	while True:
		yield counter
		counter += 1
		if counter > (1 << 31):
			counter = 0

# msg_id is global
MsgIDGenerator = NoSyncIDGenerator()


# REQ [type, msg_id, method, args, service_id]
def pack_request(method, args, serviceid):
	msgid = next(MsgIDGenerator)
	protocol = [REQUEST, msgid, method, msgpack.packb(args, use_bin_type=True), serviceid]
	data = msgpack.packb(protocol, use_bin_type=True)
	return msgid, data

# RESP [type, msg_id, error, result, _]
def pack_response(msgid, result, error=None):
	result = msgpack.packb(result, use_bin_type=True, default=lambda x: x.to_msgpack())
	protocol = [RESPONSE, msgid, error, result, '']
	data = msgpack.packb(protocol, use_bin_type=True, default=lambda x: x.to_msgpack())
	return msgid, data

# NOTI [type, _, method, args, _]
def pack_notify(method, args):
	protocol = [NOTIFY, 0, method, msgpack.packb(args, use_bin_type=True), '']
	data = msgpack.packb(protocol, use_bin_type=True)
	return 0, data

def _dict_pair(pairs):
	return {tuple(k) if isinstance(k, list) else k: v for k, v in pairs}

def unpack_message(data):
	protocol = msgpack.unpackb(data, object_pairs_hook=_dict_pair)
	if protocol[-2]:
		protocol[-2] = msgpack.unpackb(protocol[-2], object_pairs_hook=_dict_pair)
	return protocol
