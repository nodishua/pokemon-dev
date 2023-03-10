from msgpackrpc import Loop
from msgpackrpc import session
from msgpackrpc.transport import tcp

class Client(session.Session):
    """\
    Client is usaful for MessagePack RPC API.
    """

    def __init__(self, address, timeout=10, loop=None, builder=tcp, reconnect_limit=5, on_reconnect=None, pack_encoding='utf-8', unpack_encoding=None):
        loop = loop or Loop()
        session.Session.__init__(self, address, timeout, loop, builder, reconnect_limit, on_reconnect, pack_encoding, unpack_encoding)

        if timeout:
            loop.attach_periodic_callback(self.step_timeout, 1000) # each 1s

    def enableTimeout(self):
        if self._loop._periodic_callback is None:
            self._loop.attach_periodic_callback(self.step_timeout, 1000) # each 1s

    def close(self):
        self._loop.dettach_periodic_callback()
        session.Session.close(self)

    @classmethod
    def open(cls, *args):
        assert cls is Client, "should only be called on sub-classes"

        client = Client(*args)
        return Client.Context(client)

    class Context(object):
        """\
        For with statement
        """

        def __init__(self, client):
            self._client = client

        def __enter__(self):
            return self._client

        def __exit__(self, type, value, traceback):
            self._client.close()
            if type:
                return False
            return True
