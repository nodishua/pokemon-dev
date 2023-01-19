#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import json
import uuid
import urllib
import httplib
import datetime

def write_stdout(s):
	# only eventlistener protocol messages may be sent to stdout
	sys.stdout.write(s)
	sys.stdout.flush()

def write_stderr(s):
	sys.stderr.write(s)
	sys.stderr.flush()

def write_stderr_v(*args):
	sargs = ['%s' % x for x in args]
	write_stderr(' '.join(sargs) + '\n')

def write_stderr_f(format, *args):
	sargs = ['%s' % x for x in args]
	format += '\n'
	write_stderr(format % sargs)

# python -c "import uuid;print uuid.UUID(int=uuid.getnode()).hex[-12:];"
MacMap = {
	'fa163eaf04e7': 'xy-pokemon-cn-login',
	'5254002c0834': 'tc-pokemon-kr-login',
	'5254002c292f': 'ks-pokemon-tw-login',
	'525400f2da79': 'tc-pokemon-cn-login',
	'fa163e673f17': 'tc-pokemon-en-login',

	'5254004b815f': 'tc-pokemon-cn-mq',
	'5254001640e7': 'tc-pokemon-cn-mq-02',
	'5254003c45e9': 'tc-pokemon-kr-mq',
	'5254004e6680': 'ks-pokemon-tw-mq',
	'fa163e7112ef': 'tc-pokemon-en-mq',
	'fa163e4a7049': 'xy-pokemon-mq',

	'fa163ec8a219': 'xy-pokemon-cn-01',
	'fa163e14a427': 'xy-pokemon-cn-02',
	'fa163e280881': 'xy-pokemon-cn-03',
	'fa163eddb5f6': 'xy-pokemon-cn-04',
	'fa163e356f34': 'xy-pokemon-cn-05',
	'fa163ee8fcd0': 'xy-pokemon-cn-06',
	'fa163e1be057': 'xy-pokemon-cn-07',
	'fa163ece17f3': 'xy-pokemon-cn-08',
	'fa163e43722a': 'xy-pokemon-cn-09',
	'fa163eb9c582': 'xy-pokemon-cn-10',

	'525400dc4d71': 'tc-pokemon-cn-01',
	'52540014ad16': 'tc-pokemon-cn-02',
	'525400d67ce6': 'tc-pokemon-cn-03',
	'5254004a1d3f': 'tc-pokemon-cn-04',
	'5254004e25de': 'tc-pokemon-cn-05',
	'5254008e8955': 'tc-pokemon-cn-06',
	'525400e26d4f': 'tc-pokemon-cn-07',
	'5254002d564e': 'tc-pokemon-cn-08',
	'525400dfe53f': 'tc-pokemon-cn-09',
	'525400927844': 'tc-pokemon-cn-10',
	'525400b239bc': 'tc-pokemon-cn-11',
	'5254009ec7a8': 'tc-pokemon-cn-12',
	'525400a32c03': 'tc-pokemon-cn-13',
	'525400a549e3': 'tc-pokemon-cn-14',
	'52540097d3be': 'tc-pokemon-cn-15',
	'52540059a049': 'tc-pokemon-cn-16',
	'5254007feb6f': 'tc-pokemon-cn-17',
	'5254003b1bfd': 'tc-pokemon-cn-18',
	'525400d92d92': 'tc-pokemon-cn-19',
	'525400cc201d': 'tc-pokemon-cn-20',
	'5254008bc237': 'tc-pokemon-cn-21',
	'525400f8efd4': 'tc-pokemon-cn-22',
	'525400ebc10c': 'tc-pokemon-cn-23',
	'5254003a4eae': 'tc-pokemon-cn-24',
	'525400e330f6': 'tc-pokemon-cn-25',
	'525400cce5f7': 'tc-pokemon-cn-26',
	'5254003a217a': 'tc-pokemon-cn-27',
	'52540035660a': 'tc-pokemon-cn-28',
	'525400ff04e2': 'tc-pokemon-cn-29',
	'525400b62231': 'tc-pokemon-cn-30',
	'525400bc9af3': 'tc-pokemon-cn-31',
	'5254005a41cc': 'tc-pokemon-cn-32',
	'52540048416c': 'tc-pokemon-cn-33',
	'525400e288c7': 'tc-pokemon-cn-34',
	'525400ffb06c': 'tc-pokemon-cn-35',
	'525400ece8f0': 'tc-pokemon-cn-36',
	'525400dc21da': 'tc-pokemon-cn-37',
	'52540015d238': 'tc-pokemon-cn-38',
	'5254004d2bf7': 'tc-pokemon-cn-39',
	'5254003fd75a': 'tc-pokemon-cn-40',
	'52540024a2d5': 'tc-pokemon-cn-41',
	'5254008440a8': 'tc-pokemon-cn-42',
	'5254006b78a3': 'tc-pokemon-cn-43',
	'52540017dfb4': 'tc-pokemon-cn-44',
	'5254006a8fa0': 'tc-pokemon-cn_qd-01',
	'52540028252f': 'tc-pokemon-cn_qd-02',
	'525400a6c0b6': 'tc-pokemon-cn_qd-03',
	'5254006bc45e': 'tc-pokemon-cn_qd-04',
	'5254001d45d4': 'tc-pokemon-cn_qd-05',
	'5254005ba212': 'tc-pokemon-cn_qd-06',
	'52540016e1a1': 'tc-pokemon-cn_qd-07',
	'525400031fa3': 'tc-pokemon-cn_qd-08',
	'52540066ae9a': 'tc-pokemon-cn_qd-09',
	'52540023a592': 'tc-pokemon-cn_qd-10',
	'5254005a150e': 'tc-pokemon-cn_qd-11',
	'525400d2c8ca': 'tc-pokemon-cn_qd-12',
	'5254009b0c8a': 'tc-pokemon-cn_qd-13',
	'52540002286a': 'tc-pokemon-cn_qd-14',
	'52540027fb16': 'tc-pokemon-cn_qd-15',
	'525400f8084c': 'tc-pokemon-cn_qd-16',
	'525400b887ed': 'tc-pokemon-cn_qd-17',
	'525400ec8d8a': 'tc-pokemon-cn_qd-18',
	'525400cc6f77': 'tc-pokemon-cn_qd-19',
	'525400948ad7': 'tc-pokemon-cn_qd-20',
	'525400e2c2f7': 'tc-pokemon-cn_qd-21',
	'525400b9edd3': 'tc-pokemon-cn_qd-22',
	'525400a4dabc': 'tc-pokemon-cn_qd-23',
	'525400831685': 'tc-pokemon-cn_qd-24',
	'525400f4bbbf': 'tc-pokemon-cn_qd-25',
	'525400783e74': 'tc-pokemon-cn_qd-26',
	'5254009de256': 'tc-pokemon-cn_qd-27',
	'5254005c5a72': 'tc-pokemon-cn_qd-28',
	'52540032787e': 'tc-pokemon-cn_qd-29',
	'52540086d940': 'tc-pokemon-cn_qd-30',
	'52540047344f': 'tc-pokemon-cn_qd-31',
	'52540007b457': 'tc-pokemon-cn_qd-32',
	'52540098a950': 'tc-pokemon-cn_qd-33',
	'5254004415bb': 'tc-pokemon-cn_qd-34',
	'525400571848': 'tc-pokemon-cn_qd-35',
	'525400eb1f3a': 'tc-pokemon-cn_qd-36',
	'5254008d8cd6': 'tc-pokemon-cn_qd-37',
	'525400258046': 'tc-pokemon-cn_qd-38',
	'525400c341da': 'tc-pokemon-cn_qd-39',
	'52540079166c': 'tc-pokemon-cn_qd-40',
	'525400e68ce0': 'tc-pokemon-cn_qd-41',
	'525400a82f45': 'tc-pokemon-cn_qd-42',
	'52540006dd7d': 'tc-pokemon-cn_qd-43',
	'5254006ad396': 'tc-pokemon-cn_qd-44',
	'5254004a2ea1': 'tc-pokemon-cn_qd-45',
	'525400154201': 'tc-pokemon-cn_qd-46',
	'52540066cff4': 'tc-pokemon-cn_qd-47',
	'52540024755b': 'tc-pokemon-cn_qd-48',
	'525400169224': 'tc-pokemon-cn_qd-49',
	'5254002a9754': 'tc-pokemon-cn_qd-50',
	'525400c5434d': 'tc-pokemon-cn_qd-51',
	'52540033e7fd': 'tc-pokemon-cn_qd-52',
	'525400e94b5b': 'tc-pokemon-cn_qd-53',
	'5254005d72d9': 'tc-pokemon-cn_qd-54',
	'525400acf0b9': 'tc-pokemon-cn_qd-55',
	'5254009b82db': 'tc-pokemon-cn_qd-56',
	'5254000cd82c': 'tc-pokemon-cn_qd-57',
	'525400d4fb52': 'tc-pokemon-cn_qd-58',
	'5254005ad3b7': 'tc-pokemon-cn_qd-59',
	'525400c222f5': 'tc-pokemon-cn_qd-60',
	'525400bebdf7': 'tc-pokemon-cn_qd-61',
	'5254009b6804': 'tc-pokemon-cn_qd-62',
	'5254001ccf9b': 'tc-pokemon-cn_qd-63',
	'5254002bed75': 'tc-pokemon-cn_qd-64',
	'525400bc9df7': 'tc-pokemon-cn_qd-65',
	'5254004ca242': 'tc-pokemon-cn_qd-66',
	'525400f53e16': 'tc-pokemon-cn_qd-67',
	'525400d37828': 'tc-pokemon-cn_qd-68',
	'525400c61b64': 'tc-pokemon-cn_qd-69',
	'5254007f6a74': 'tc-pokemon-cn_qd-70',
	'525400551c4a': 'tc-pokemon-cn_qd-71',
	'525400a3d337': 'tc-pokemon-cn_qd-72',
	'5254004537ec': 'tc-pokemon-cn_qd-73',
	'5254002f1f31': 'tc-pokemon-cn_qd-74',
	'52540069a0af': 'tc-pokemon-cn_qd-75',
	'525400fb4dad': 'tc-pokemon-cn_qd-76',
	'525400caa21e': 'tc-pokemon-cn_qd-77',
	'525400ec0174': 'tc-pokemon-cn_qd-78',
	'525400a6d469': 'tc-pokemon-cn_qd-79',
	'525400bc864d': 'tc-pokemon-cn_qd-80',
	'525400d66907': 'tc-pokemon-cn_qd-81',
	'525400149c4c': 'tc-pokemon-cn_qd-82',
	'525400baf519': 'tc-pokemon-cn_qd-83',
	'525400a2facb': 'tc-pokemon-cn_qd-84',
	'52540072a0d5': 'tc-pokemon-cn_qd-85',
	'525400da886c': 'tc-pokemon-cn_qd-86',
	'525400685c1f': 'tc-pokemon-cn_qd-87',
	'5254006daebc': 'tc-pokemon-cn_qd-88',
	'52540037b264': 'tc-pokemon-cn_qd-89',
	'5254006a235a': 'tc-pokemon-cn_qd-90',
	'525400ab7540': 'tc-pokemon-cn_qd-91',
	'525400753b90': 'tc-pokemon-cn_qd-92',
	'5254001f7266': 'tc-pokemon-cn_qd-93',
	'525400ad036b': 'tc-pokemon-cn_qd-94',
	'525400238555': 'tc-pokemon-cn_qd-95',
	'52540076fd71': 'tc-pokemon-cn_qd-96',
	'525400f31bd0': 'tc-pokemon-cn_qd-97',
	'52540036f4b3': 'tc-pokemon-cn_qd-98',
	'525400b7d775': 'tc-pokemon-cn_qd-99',
	'525400148275': 'tc-pokemon-cn_qd-100',
	'525400fd7b17': 'tc-pokemon-cn_qd-101',
	'525400631223': 'tc-pokemon-cn_qd-102',
	'5254006fc1c0': 'tc-pokemon-cn_qd-103',
	'525400655d50': 'tc-pokemon-cn_qd-104',
	'5254009aa820': 'tc-pokemon-cn_qd-105',
	'525400a2fbb7': 'tc-pokemon-cn_qd-106',
	'525400ad3db5': 'tc-pokemon-cn_qd-107',
	'5254007a5d14': 'tc-pokemon-cn_qd-108',
	'52540036eec9': 'tc-pokemon-cn_qd-109',
	'525400f31f65': 'tc-pokemon-cn_qd-110',
	'5254001e9f66': 'tc-pokemon-cn_qd-111',
	'525400ef8ce4': 'tc-pokemon-cn_qd-112',
	'52540067b9e9': 'tc-pokemon-cn_qd-113',
	'525400d782e9': 'tc-pokemon-cn_qd-114',
	'525400c562e1': 'tc-pokemon-cn_qd-115',
	'525400563519': 'tc-pokemon-cn_qd-116',
	'52540072ca15': 'tc-pokemon-cn_qd-117',
	'525400557ca1': 'tc-pokemon-cn_qd-118',
	'52540044e201': 'tc-pokemon-cn_qd-119',
	'5254009f0115': 'tc-pokemon-cn_qd-120',
	'525400a46491': 'tc-pokemon-cn_qd-121',
	'525400d9333e': 'tc-pokemon-cn_qd-122',
	'5254001b39d8': 'tc-pokemon-cn_qd-123',
	'525400ad0962': 'tc-pokemon-cn_qd-124',
	'525400538e1b': 'tc-pokemon-cn_qd-125',
	'5254003d7c4f': 'tc-pokemon-cn_qd-126',
	'525400e93ac1': 'tc-pokemon-cn_qd-127',

	'52540062944a': 'tc-pokemon-kr-01',
	'5254004712a3': 'tc-pokemon-kr-02',
	'525400c494bb': 'tc-pokemon-kr-03',
	'525400546c7b': 'tc-pokemon-kr-04',
	'525400fb618f': 'tc-pokemon-kr-05',
	'525400c9ec5e': 'tc-pokemon-kr-06',
	'52540097468f': 'tc-pokemon-kr-07',
	'5254006c4a45': 'tc-pokemon-kr-08',
	'525400157d24': 'tc-pokemon-kr-09',
	'5254005ddde8': 'tc-pokemon-kr-10',
	'5254008ad98a': 'tc-pokemon-kr-11',
	'525400641e51': 'tc-pokemon-kr-12',
	'52540008cbcd': 'tc-pokemon-kr-13',
	'5254001a68a2': 'tc-pokemon-kr-14',
	'5254000cfef9': 'tc-pokemon-kr-15',
	'525400fc35b6': 'tc-pokemon-kr-16',

	'fa163e331be2': 'tc-pokemon-en-01',
	'fa163e4a0c04': 'tc-pokemon-en-02',
	'fa163e7b4579': 'tc-pokemon-en-03',
	'fa163e07d72a': 'tc-pokemon-en-04',
	'fa163e25054a': 'tc-pokemon-en-05',
	'fa163e25de6c': 'tc-pokemon-en-06',
	'fa163e4125a1': 'tc-pokemon-en-07',
	'fa163eed5951': 'tc-pokemon-en-08',
	'fa163e5441d6': 'tc-pokemon-en-09',
	'fa163e4b09d9': 'tc-pokemon-en-10',
	'fa163e4fc7a8': 'tc-pokemon-en-11',
	'fa163ec9c82c': 'tc-pokemon-en-12',
	'fa163e3612d5': 'tc-pokemon-en-13',
	'fa163ebe2734': 'tc-pokemon-en-14',
	'fa163e49aa47': 'tc-pokemon-en-15',
	'fa163e840735': 'tc-pokemon-en-16',
	'fa163ee0a08b': 'tc-pokemon-en-17',
	'fa163e4d4f46': 'tc-pokemon-en-18',
	'fa163e258fb7': 'tc-pokemon-en-19',

	'52540099c870': 'ks-pokemon-tw-01',
	'52540017225e': 'ks-pokemon-tw-02',
	'5254005ed102': 'ks-pokemon-tw-03',
	'525400655c44': 'ks-pokemon-tw-04',
	'52540032c553': 'ks-pokemon-tw-05',
	'52540093ab0a': 'ks-pokemon-tw-06',
	'52540099137e': 'ks-pokemon-tw-07',
	'5254003eb29f': 'ks-pokemon-tw-08',
	'5254008d33f3': 'ks-pokemon-tw-09',
	'52540062c7a5': 'ks-pokemon-tw-10',
}

def ding(title, digest, msg):
	if isinstance(digest, str):
		digest = '\n\n'.join(digest.split('\n'))
	else:
		digest = '\n\n'.join(digest)
	if isinstance(msg, str):
		msg = '\n\n> '.join(msg.split('\n'))
	else:
		msg = '\n\n> '.join(msg)
	params = {
		"msgtype": "markdown",
		"markdown": {
			"title": "alarm",
			"text": "## " + title + "\n\n" + digest + "\n\n>" + msg + "\n",
		}
	 }
	headers = {'content-type': 'application/json;charset=UTF-8', 'Accept':'text/json'}
	httpClient = httplib.HTTPSConnection("oapi.dingtalk.com", 443, timeout=30)
	httpClient.request("POST", "/robot/send?access_token=cf33ac5c154294f61591e4da4e7150f8448c2d5207a82dae73397253ae967c9e", json.dumps(params), headers)
	response = httpClient.getresponse()
	if response.status != 200:
		write_stderr_f('%s\n%s', response.reason, response.read())

def postding(headers, body):
	title = '口袋运维报警'
	mac = uuid.UUID(int=uuid.getnode()).hex[-12:]
	mac = MacMap.get(mac, mac)
	msghead = [str(datetime.datetime.now()), 'mac: %s' % mac, 'event: %s' % headers.get('eventname')]
	msg = ['%s: %s' % t for t in body.iteritems()]
	# mem = machine.get_mem_info()
	# shows = set(['total', 'used', 'available'])
	# msghead += ['mem-percent: %s %%' % mem['percent']]
	# msghead += sorted(['mem-%s: %s' % (k, human_read(v)) for k, v in mem.iteritems() if k in shows])
	# msghead += sorted(['%s: %s' % (k, len(v)) for k, v in servers.iteritems() if len(v) > 0])
	# if mac in MacMap:
	# 	title = '口袋运维报警 %s' % MacMap[mac]
	ding(title, msghead, msg)

def main():
	while 1:
		# transition from ACKNOWLEDGED to READY
		write_stdout('READY\n')

		# read header line and print it to stderr
		line = sys.stdin.readline()
		write_stderr("[line]" + line)

		# read event payload and print it to stderr
		headers = dict([ x.split(':') for x in line.split() ])
		data = sys.stdin.read(int(headers['len']))
		write_stderr("[data]" + data + "\n")
		body = dict([ x.split(':') for x in data.split() ])

		# http://supervisord.org/events.html
		# [line]ver:3.0 server:supervisor serial:9115 pool:lis_test poolserial:1 eventname:PROCESS_STATE_EXITED len:69
		# [data]processname:cat groupname:cat from_state:RUNNING expected:0 pid:31498
		if headers.get('eventname', "none") == "PROCESS_STATE_EXITED":
			postding(headers, body)

		# transition from READY to ACKNOWLEDGED
		write_stdout('RESULT 2\nOK')

if __name__ == '__main__':
	main()

