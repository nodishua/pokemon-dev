# -*- coding: utf-8 -*-
"""
the url structure of website
"""

import handlers.index
import handlers.dashboard
import handlers.crashinfo
import handlers.dbtables
import handlers.query

from tornado.web import RequestHandler
import sys

modules = [
    sys.modules['handlers.index'],
    sys.modules['handlers.dashboard'],
    sys.modules['handlers.crashinfo'],
    sys.modules['handlers.dbtables'],
    sys.modules['handlers.query']
]

urlMaps = []

def _makeUrlHandlerMap():
    urls = []
    for m in modules:
        for x in dir(m):
            cls = getattr(m, x)
            if type(cls) == type and issubclass(cls, RequestHandler) and hasattr(cls, 'url'):
                if cls.url in urls:
                    raise Exception, "this url '%s' is exist!"% cls.url

                urls.append(cls.url)
                urlMaps.append((cls.url, cls))

_makeUrlHandlerMap()