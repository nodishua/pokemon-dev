#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from . import query
from . import dashboard
from . import _gm
from . import _operation
from . import _test
from . import _data_query
from . import _area

from tornado.web import RequestHandler

import sys


modules = [
    sys.modules['gm.handler.query'],
	sys.modules['gm.handler.dashboard'],
    sys.modules['gm.handler._gm'],
    sys.modules['gm.handler._operation'],
    sys.modules['gm.handler._test'],
    sys.modules['gm.handler._data_query'],
    sys.modules['gm.handler._area'],
]

handlers = []

def _makeUrlHandlerMap():
    urls = []
    for m in modules:
        for x in dir(m):
            cls = getattr(m, x)
            if type(cls) == type and issubclass(cls, RequestHandler) and hasattr(cls, 'url'):
                if cls.url in urls:
                    raise Exception, "this url '%s' is exist!"% cls.url

                urls.append(cls.url)
                handlers.append((cls.url, cls))

_makeUrlHandlerMap()