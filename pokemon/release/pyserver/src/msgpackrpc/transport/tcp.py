import msgpack
from tornado import tcpserver
from tornado.iostream import IOStream

import msgpackrpc.message
from msgpackrpc.error import RPCError, TransportError

import time

class BaseSocket(object):
    def __init__(self, stream, encodings):
        self._stream = stream
        self._packer = msgpack.Packer(encoding=encodings[0], default=lambda x: x.to_msgpack())
        self._unpacker = msgpack.Unpacker(encoding=encodings[1], object_pairs_hook=self._dict_pair)

    @staticmethod
    def _dict_pair(pairs):
        return {tuple(k) if isinstance(k, list) else k: v for k, v in pairs}

    def close(self):
        self._stream.close()

    def send_message(self, message, callback=None):
        # st = time.time()
        msg = self._packer.pack(message)
        # print time.time(), 'send_message pack len', len(msg), 'cost', time.time() - st
        self._stream.write(msg, callback=callback)

    def on_read(self, data):
        if self._stream.closed():
            return

        try:
            # print time.time(), 'on_read', len(data)
            # st = time.time()
            self._unpacker.feed(data)
            # print time.time(), 'on_read unpack cost', time.time() - st
            for message in self._unpacker:
                self.on_message(message)
        except:
            self.close()
            raise

    def on_message(self, message, *args):
        msgsize = len(message)
        if msgsize != 4 and msgsize != 3:
            raise RPCError("Invalid MessagePack-RPC protocol: message = {0}".format(message))

        msgtype = message[0]
        if msgtype == msgpackrpc.message.REQUEST:
            self.on_request(message[1], message[2], message[3])
        elif msgtype == msgpackrpc.message.RESPONSE:
            self.on_response(message[1], message[2], message[3])
        elif msgtype == msgpackrpc.message.NOTIFY:
            self.on_notify(message[1], message[2])
        else:
            raise RPCError("Unknown message type: type = {0}".format(msgtype))

    def on_request(self, msgid, method, param):
        raise NotImplementedError("on_request not implemented")

    def on_response(self, msgid, error, result):
        raise NotImplementedError("on_response not implemented")

    def on_notify(self, method, param):
        raise NotImplementedError("on_notify not implemented")


class ClientSocket(BaseSocket):
    def __init__(self, stream, transport, encodings):
        BaseSocket.__init__(self, stream, encodings)
        self._transport = transport
        self._stream.set_close_callback(self.on_close)

    def connect(self):
        self._stream.connect(self._transport._address.unpack(), self.on_connect)

    def on_connect(self):
        self._stream.read_until_close(self.on_read, self.on_read)
        self._transport.on_connect(self)

    def on_connect_failed(self):
        self._transport.on_connect_failed(self)

    def on_close(self):
        self._transport.on_close(self)

    def on_response(self, msgid, error, result):
        self._transport._session.on_response(msgid, error, result)


class ClientTransport(object):
    def __init__(self, session, address, reconnect_limit, on_reconnect, encodings=('utf-8', None)):
        self._session = session
        self._address = address
        self._encodings = encodings
        self._reconnect_limit = reconnect_limit
        self._on_reconnect = on_reconnect

        self._connecting = 0
        self._pending = []
        self._sockets = []
        self._closed  = False
        self._wait_connect = False

    def send_message(self, message, callback=None):
        if self._closed:
            return

        if len(self._sockets) == 0:
            self.connect()
            self._pending.append((message, callback))
        else:
            sock = self._sockets[0]
            sock.send_message(message, callback)

    def connect(self):
        if self._wait_connect or self._closed:
            return

        self._connecting += 1
        self._wait_connect = True
        ioloop = self._session._loop._ioloop
        stream = IOStream(self._address.socket(), io_loop=ioloop)
        socket = ClientSocket(stream, self, self._encodings)
        socket.connect()

    def close(self):
        for sock in self._sockets:
            sock.close()

        self._connecting = 0
        self._pending = []
        self._sockets = []
        self._closed  = True
        self._wait_connect = False

    def on_connect(self, sock):
        self._sockets.append(sock)
        if self._connecting > 1 and self._on_reconnect:
            self._on_reconnect()

        for pending, callback in self._pending:
            sock.send_message(pending, callback)
        self._pending = []
        self._wait_connect = False

    def on_connect_failed(self, sock):
        self._wait_connect = False

        if self._reconnect_limit < 0 or self._connecting < self._reconnect_limit:
            self._session.on_connect_failed(TransportError("Socket Closed"))
        else:
            self._connecting = 0
            self._pending = []
            self._session.on_close(TransportError("Retry connection over the limit"))

    def on_close(self, sock):
        # Avoid calling self.on_connect_failed after self.close called.
        if self._closed:
            return

        if sock in self._sockets:
            self._sockets.remove(sock)
            if len(self._sockets) == 0:
                self.on_connect_failed(sock)
        else:
            # Tornado does not have on_connect_failed event.
            self.on_connect_failed(sock)


class ServerSocket(BaseSocket):
    def __init__(self, stream, transport, encodings):
        BaseSocket.__init__(self, stream, encodings)
        self._transport = transport
        self._stream.read_until_close(self.on_read, self.on_read)

    def on_request(self, msgid, method, param):
        self._transport._server.on_request(self, msgid, method, param)

    def on_notify(self, method, param):
        self._transport._server.on_notify(method, param)


class MessagePackServer(tcpserver.TCPServer):
    def __init__(self, transport, io_loop=None, encodings=None):
        self._transport = transport
        self._encodings = encodings
        tcpserver.TCPServer.__init__(self, io_loop=io_loop)

    def handle_stream(self, stream, address):
        ServerSocket(stream, self._transport, self._encodings)

class ServerTransport(object):
    def __init__(self, address, encodings=('utf-8', None)):
        self._address = address;
        self._encodings = encodings

    def listen(self, server):
        self._server = server;
        self._mp_server = MessagePackServer(self, io_loop=self._server._loop._ioloop, encodings=self._encodings)
        self._mp_server.listen(self._address.port)

    def close(self):
        self._mp_server.stop()
