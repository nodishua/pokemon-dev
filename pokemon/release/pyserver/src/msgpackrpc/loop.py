from tornado import ioloop
import traceback

class Loop(object):
    """\
    An I/O loop class which wraps the Tornado's ioloop.
    """

    @staticmethod
    def instance():
        return Loop(ioloop.IOLoop.current())

    def __init__(self, loop=None):
        self._ioloop = loop or ioloop.IOLoop()
        self._ioloop.make_current()
        self._periodic_callback = None

    def start(self):
        """\
        Starts the Tornado's ioloop if it's not running.
        """

        try:
            self._ioloop.start()
        except:
            traceback.print_exc()

    def stop(self):
        """\
        Stops the Tornado's ioloop if it's running.
        """

        try:
            self._ioloop.stop()
        except:
            traceback.print_exc()

    def attach_periodic_callback(self, callback, callback_time):
        if self._periodic_callback is not None:
            self.dettach_periodic_callback()

        self._periodic_callback = ioloop.PeriodicCallback(callback, callback_time, self._ioloop)
        self._periodic_callback.start()
        return self._periodic_callback

    def dettach_periodic_callback(self):
        if self._periodic_callback is not None:
            self._periodic_callback.stop()
        self._periodic_callback = None
