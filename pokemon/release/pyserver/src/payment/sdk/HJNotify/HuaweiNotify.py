# -*- coding:utf-8 –*-

from NotifyBase import NotifyBase
from HJProxyConfig import HJProxyConfig

import base64

class HuaweiNotify(NotifyBase):
    def invokeService(self, post):
        if not self.__rsaVerify(post):
            return False

        money = int(float(post['amount']) * 100)
        info = base64.b64decode(post['extReserved'])

        data = {
            'userNo': post['userName'],
            'paySuccess':     1,
            'myOrderNo':      post['requestId'],
            'channelOrderNo': post['orderId'],
            'money':          money,  # 以分为单位，整形
            'cpPrivateInfo':  info,
            'channel':        'huawei'
        }

        return data

    def sendResponse(self, resp = 'success'):
        if 'success' == resp:
            ret = '{"result": 0}'
        else:
            ret = '{"result": 1}'

        return ret

    def __rsaVerify(self, contents):
        sorted_contents = sorted(contents.items())
        str_contents = '&'.join('%s=%s' % (str(k), str(v)) for k, v in sorted_contents if k != 'sign')

        publickey = HJProxyConfig.HUAWEI_PUBLIC_KEY

        return self.rsa_verify(publickey, str_contents, contents['sign'])