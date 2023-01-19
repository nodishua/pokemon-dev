from CoolpadNotify import CoolpadNotify
from OppoNotify import OppoNotify
from HuaweiNotify import HuaweiNotify
from LenovoNotify import LenovoNotify
from GioneeNotify import GioneeNotify
from VivoNotify import VivoNotify

class HJNotifyProxy:

    @staticmethod
    def getChannelInstance(channelName):
        proxy = channelName.capitalize()
        if proxy == 'Coolpad':
            obj = CoolpadNotify()
        elif proxy == 'Oppo':
            obj = OppoNotify()
        elif proxy == 'Huawei':
            obj = HuaweiNotify()
        elif proxy == 'Lenovo':
            obj = LenovoNotify()
        elif proxy == 'Gionee':
            obj = GioneeNotify()
        elif proxy == 'Vivo':
            obj = VivoNotify()
        else:
            obj = False

        return obj