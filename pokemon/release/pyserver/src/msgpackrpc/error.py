class RPCError(Exception):
    CODE = ".RPCError"

    def __init__(self, message, **kwargs):
        Exception.__init__(self, message)

    @property
    def code(self):
        return self.__class__.CODE

    def to_msgpack(self):
        return [self.message]

    @staticmethod
    def from_msgpack(message):
        return RPCError(message)

class TimeoutError(RPCError):
    CODE = ".TimeoutError"
    pass

class TransportError(RPCError):
    CODE = ".TransportError"
    pass

class SessionError(RPCError):
    CODE = ".SessionError"
    pass

class CallError(RPCError):
    CODE = ".CallError"

    def __init__(self, msg, **kwargs):
        Exception.__init__(self, msg)
        self.msg = msg
        self.kwargs = kwargs

    def to_msgpack(self):
        return {'msg': self.msg, 'kwargs': self.kwargs}

    @staticmethod
    def from_msgpack(msgpack):
        msg, kwargs = '', {}
        # compatible with RPCError
        if not isinstance(msgpack, dict):
            msg = msgpack
        else:
            msg = msgpack.pop('msg')
            kwargs = msgpack.pop('kwargs')
        return CallError(msg, **kwargs)

class NoMethodError(CallError):
    CODE = ".CallError.NoMethodError"
    pass

class ArgumentError(CallError):
    CODE = ".CallError.ArgumentError"
    pass
