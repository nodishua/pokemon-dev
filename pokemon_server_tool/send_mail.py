#!/usr/bin/python
# -*- coding: utf-8 -*-


import sys
sys.path.append('../server/src')

from service_forward import *

ROLE_LIST = [
# ('game.cn.1' ,'5de789db5ec29639c548ec58'),
# ('game.cn.1' ,'5de7960b5ec29639c5492505'),

]

def send_mail():
	content = '''Hi，训练家：

今天石英大会出现积分异常问题，对此我们深表歉意，感谢您对游戏的支持，祝您游戏愉快。
'''

	with open_forward('cn') as client:
		print 'ROLE_LIST', len(ROLE_LIST)
		for key, objid in ROLE_LIST:
			print key, objid
			# key = 'game.cn.6'
			# objid = '5e99ed8f7942ed459db88620'
			resp = client.call('gmSendMail', string2objectid(objid), 1, '大舌头', '积分负数问题补偿', content, {6001: 5, 'gold': 500000}, service_id=key)
			print resp

if __name__ == '__main__':
	send_mail()
