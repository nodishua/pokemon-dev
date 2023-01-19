# -*- coding:utf-8 –*-

from NotifyBase import NotifyBase
from HJProxyConfig import HJProxyConfig


class OppoNotify(NotifyBase):
    def invokeService(self, post):
        if not self.__rsaVerify(post):
            return False

        money = int(post['price']);

        data = {
            'userNo': post['userId'],
            'paySuccess':     1,
            'myOrderNo':      post['partnerOrder'],
            'channelOrderNo': post['notifyId'],
            'money':          money,  # 以分为单位，整形
            'cpPrivateInfo':  post['attach'],
            'channel':        'oppo'
        }

        return data

    def sendResponse(self, resp = 'success'):
        if 'success' == resp:
            ret = 'result=OK&resultMsg=success'
        else:
            ret = 'result=FAIL&resultMsg=fail'

        return ret

    def __rsaVerify(self, contents):
        str_contents = "notifyId=" + str(contents['notifyId']) + "&partnerOrder=" + str(contents['partnerOrder']) \
                       + "&productName=" + str(contents['productName']) + "&productDesc=" \
                       + str(contents['productDesc']) + "&price=" + str(contents['price']) + "&count=" \
                       + str(contents['count']) + "&attach=" + str(contents['attach'])

        publickey = HJProxyConfig.OPPO_PUBLIC_KEY

        return self.rsa_verify(publickey, str_contents, contents['sign'])