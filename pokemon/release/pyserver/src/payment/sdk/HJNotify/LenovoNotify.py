# -*- coding:utf-8 –*-

from NotifyBase import NotifyBase
from HJProxyConfig import HJProxyConfig
import json
import base64
import M2Crypto


class LenovoNotify(NotifyBase):
    def invokeService(self, post):
        if not self.__rsaVerify(post):
            return False

        transdata = json.loads(post['transdata'])
        money = int(transdata['money'])

        data = {
            'userNo': '',
            'paySuccess':     1,
            'myOrderNo':      transdata['exorderno'],
            'channelOrderNo': transdata['transid'],
            'money':          money,  #以分为单位，整形
            'cpPrivateInfo':  transdata['cpprivate'],
            'channel':       'lenovo'
        }

        return data

    def sendResponse(self, resp = 'success'):
        if 'success' == resp:
            ret = 'SUCCESS'
        else:
            ret = 'FAILURE'

        return ret

    def __rsaVerify(self, contents):
        sign = str(contents['sign'])
        str_contents = str(contents['transdata'])

        private_key = HJProxyConfig.LENOVO_KEY
        pem = self.chunk_split(private_key)
        pem = "-----BEGIN PRIVATE KEY-----\n"+pem+"-----END PRIVATE KEY-----\n"
        pri_key = M2Crypto.EVP.load_key_string(pem)
        pri_key.sign_init()
        pri_key.sign_update(str_contents)
        signature = base64.b64encode(pri_key.sign_final())

        return sign == signature