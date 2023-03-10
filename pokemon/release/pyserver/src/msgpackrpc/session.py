from msgpackrpc import Loop
from msgpackrpc import message
from msgpackrpc.future import Future
from msgpackrpc.transport import tcp
from msgpackrpc.compat import iteritems
from msgpackrpc.error import TimeoutError

import traceback

class Session(object):
    """\
    Session processes send/recv request of the message, by using underlying
    transport layer.

    self._request_table(request table) stores the relationship between messageid and
    corresponding future. When the new requets are sent, the Session generates
    new message id and new future. Then the Session registers them to request table.

    When it receives the message, the Session lookups the request table and set the
    result to the corresponding future.
    """

    def __init__(self, address, timeout, loop=None, builder=tcp, reconnect_limit=5, on_reconnect=None, pack_encoding='utf-8', unpack_encoding=None):
        """\
        :param address: address of the server.
        :param loop:    context object.
        :param builder: builder for creating transport layer
        """

        self._loop = loop or Loop()
        self._address = address
        self._timeout = timeout
        self._transport = builder.ClientTransport(self, self._address, reconnect_limit, on_reconnect, encodings=(pack_encoding, unpack_encoding))
        self._generator = _NoSyncIDGenerator()
        self._request_table = {}

    @property
    def address(self):
        return self._address

    def call(self, method, *args):
        return self.send_request(method, args).get()

    def call_async(self, method, *args):
        return self.send_request(method, args)

    def send_request(self, method, args):
        # need lock?
        msgid = next(self._generator)
        future = Future(self._loop, self._timeout)
        self._request_table[msgid] = future
        try:
            self._transport.send_message([message.REQUEST, msgid, method, args])
        except Exception as e:
            # exception saved in Future, it lost real traceback stack
            if not hasattr(e, 'to_msgpack'):
                e = "%s\n%s" % (str(e) , traceback.format_exc())
            # if had timeout, will set_error twice, cause future._callbacks is None
            self._request_table.pop(msgid)
            future.set_error(e)
        return future

    def notify(self, method, *args):
        def callback():
            self._loop.stop()
        self._transport.send_message([message.NOTIFY, method, args], callback=callback)
        self._loop.start()

    def close(self):
        if self._transport:
            self._transport.close()
        self._transport = None
        self._request_table = {}

    def on_close(self, reason):
       self.on_connect_failed(reason)
       self.close()

    def on_connect_failed(self, reason):
        """
        The callback called when the connection failed.
        Called by the transport layer.
        """
        # set error for all requests
        for msgid, future in iteritems(self._request_table):
            future.set_error(reason)

        # self.close()
        # modify by huangwei, 2015-2-26
        # always maintain the session, no close
        self._request_table = {}
        self._loop.stop()

    def on_response(self, msgid, error, result):
        """\
        The callback called when the message arrives.
        Called by the transport layer.
        """

        if not msgid in self._request_table:
            # TODO: Check timed-out msgid?
            #raise RPCError("Unknown msgid: id = {0}".format(msgid))
            return
        future = self._request_table.pop(msgid)

        if error is not None:
            future.set_error(error)
        else:
            future.set_result(result)
        self._loop.stop()

    def on_timeout(self, msgid):
        future = self._request_table.pop(msgid)
        future.set_error(TimeoutError("%d Request timed out" % msgid))

    def step_timeout(self):
        timeouts = []
        for msgid, future in iteritems(self._request_table):
            if future.step_timeout():
                timeouts.append(msgid)

        if len(timeouts) == 0:
            return

        self._loop.stop()
        for timeout in timeouts:
            future = self._request_table.pop(timeout)
            future.set_error(TimeoutError("%d Request timed out" % timeout))
        self._loop.start()


def _NoSyncIDGenerator():
    """
    Message ID Generator.

    NOTE: Don't use in multithread. If you want use this
    in multithreaded application, use lock.
    """
    counter = 0
    while True:
        yield counter
        counter += 1
        if counter > (1 << 30):
            counter = 0
