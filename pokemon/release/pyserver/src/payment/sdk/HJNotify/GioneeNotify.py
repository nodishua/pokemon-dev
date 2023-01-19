# -*- coding:utf-8 –*-

from NotifyBase import NotifyBase
from HJProxyConfig import HJProxyConfig

class GioneeNotify(NotifyBase):
    def invokeService(self, post):
        if not self.__rsaVerify(post):
            return False

        money = float(post['deal_price']) * 100

        ret_data = {
            'userNo': post['user_id'],
            'paySuccess':     1,
            'myOrderNo':      post['out_order_no'],
            'channelOrderNo': '', # 由创建订单时返回
            'money':          money,  #以分为单位，整形
            'cpPrivateInfo':   '',
            'channel':        'gionee'
        }

        return ret_data

    def sendResponse(self, resp = 'success'):
        if 'success' == resp:
            ret = 'success'
        else:
            ret = 'fail'

        return ret

    def __rsaVerify(self, contents):
        sorted_contents = sorted(contents.items())
        str_contents = '&'.join('%s=%s' % (str(k), str(v)) for k, v in sorted_contents if k != 'sign')

        publickey = HJProxyConfig.GIONEE_PUBLIC_KEY
        return self.rsa_verify(publickey, str_contents, contents['sign'])