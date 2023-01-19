# -*- coding:utf-8 –*-

from NotifyBase import NotifyBase
from HJProxyConfig import HJProxyConfig
import json

class CoolpadNotify(NotifyBase):
    def invokeService(self, post):
        if not self.__rsaVerify(post):
            return False

        transdata = json.loads(post['transdata'])
        money = int(float(transdata['money'])*100)

        ret_data = {
            'userNo': transdata['appuserid'],
            'paySuccess':     1 if transdata['result'] == 0 else 0,
            'myOrderNo':      transdata['cporderid'], # transdata['exorderno'],
            'channelOrderNo': transdata['transid'],
            'money':          money,  #以分为单位，整形
            'cpPrivateInfo':  transdata['cpprivate'],
            'channel':        'coolpad'
        }

        return ret_data

    def sendResponse(self, resp = 'success'):
        if 'success' == resp:
            ret = 'SUCCESS'
        else:
            ret = 'FAILURE'

        return ret

    def __rsaVerify(self, contents):
        str_contents = str(contents['transdata'])
        sign = contents['sign']

        publickey = HJProxyConfig.COOLPAD_KEY

        return self.rsa_verify(publickey, str_contents, sign, 'md5')