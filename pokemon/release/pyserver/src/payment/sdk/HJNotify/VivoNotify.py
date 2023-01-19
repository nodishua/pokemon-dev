# -*- coding:utf-8 –*-

from NotifyBase import NotifyBase
from HJProxyConfig import HJProxyConfig
import hashlib


class VivoNotify(NotifyBase):
    def invokeService(self, post):
        if not self.__rsaVerify(post):
            return False

        money = int(post['orderAmount'])
        ret_data = {
            'userNo':         post['uid'],
            'paySuccess':     1 if post['tradeStatus'] == '0000' else 0,
            'myOrderNo':      post['cpOrderNumber'],
            'channelOrderNo': post['orderNumber'],
            'money':          money,  # 以分为单位，整形
            'cpPrivateInfo':  post['extInfo'],
            'channel':       'vivo'
        }
        return ret_data

    def sendResponse(self, resp = 'success'):
        if 'success' == resp:
            return 'HTTP/1.1 200 OK'
        else:
            return 'HTTP/1.1 403 Forbidden'

    def __rsaVerify(self, contents):
        signature = contents['signature']
        del(contents['signMethod'])
        del(contents['signature'])

        sorted_contents = sorted(contents.items())
        signature_str = '&'.join('%s=%s' % (str(k), str(v)) for k, v in sorted_contents if v != '')

        signature_str = hashlib.md5(signature_str + '&' + hashlib.md5(HJProxyConfig.VIVO_CP_KEY).hexdigest()).hexdigest()
        return signature == signature_str