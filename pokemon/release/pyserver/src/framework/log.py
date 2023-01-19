# -*- coding: utf-8 -*-

"""
Logging support for Game.

Copy from Tornado.log
"""
from __future__ import absolute_import

import logging
import logging.handlers
import sys
import collections

# for test
if __name__ == '__main__':
	sys.path.append('../')

from tornado.escape import _unicode
from tornado.util import unicode_type, basestring_type

try:
	import curses
except ImportError:
	curses = None


class DebugLog(object):
	def __init__(self, filename = None, console = True):
		self.buff = ''
		self.sys_out = sys.stdout
		self.sys_err = sys.stderr
		self.console = console
		self.logfile = None
		if filename is not None:
			self.logfile = open(filename + '.out', 'w')
		sys.stdout = self
		sys.stderr = self

	def write(self, stream):
		if self.console:
			self.sys_out.write(stream)
		if self.logfile:
			self.logfile.write(stream)

	def flush(self):
		if self.console:
			self.sys_out.flush()
		if self.logfile:
			self.logfile.flush()

# DebugLog(None, True)


def _stderr_supports_color():
	color = False
	if curses and hasattr(sys.stderr, 'isatty') and sys.stderr.isatty():
		try:
			curses.setupterm()
			if curses.tigetnum("colors") > 0:
				color = True
		except Exception:
			pass
	return color


def _safe_unicode(s):
	# unicode convert move to `NSQWriteStream` by huangwei 2016-04-20
	return s
	# try:
	# 	return _unicode(s)
	# except UnicodeDecodeError:
	# 	return repr(s)


class LogFormatter(logging.Formatter):
	"""Log formatter used in Tornado.

	Key features of this formatter are:

	* Color support when logging to a terminal that supports it.
	* Timestamps on every log line.
	* Robust against str/bytes encoding problems.

	This formatter is enabled automatically by
	`tornado.options.parse_command_line` (unless ``--logging=none`` is
	used).
	"""
	DEFAULT_FORMAT = '%(color)s[%(levelname)1.1s %(asctime)s %(module)s:%(lineno)d]%(end_color)s %(message)s'
	ENHANCE_FORMAT = '%(color)s[%(name)s %(levelname)1.1s %(asctime)s %(clientip)s %(module)s:%(lineno)d]%(end_color)s %(message)s'
	DEFAULT_DATE_FORMAT = '%y%m%d %H:%M:%S'
	DEFAULT_COLORS = {
		logging.DEBUG: 4,  # Blue
		logging.INFO: 2,  # Green
		logging.WARNING: 3,  # Yellow
		logging.ERROR: 1,  # Red
	}


	def __init__(self, color=True, fmt=ENHANCE_FORMAT,
				 datefmt=DEFAULT_DATE_FORMAT, colors=DEFAULT_COLORS):
		r"""
		:arg bool color: Enables color support.
		:arg string fmt: Log message format.
		  It will be applied to the attributes dict of log records. The
		  text between ``%(color)s`` and ``%(end_color)s`` will be colored
		  depending on the level if color support is on.
		:arg dict colors: color mappings from logging level to terminal color
		  code
		:arg string datefmt: Datetime format.
		  Used for formatting ``(asctime)`` placeholder in ``prefix_fmt``.

		.. versionchanged:: 3.2

		   Added ``fmt`` and ``datefmt`` arguments.
		"""
		logging.Formatter.__init__(self, datefmt=datefmt)
		self._fmt = fmt

		self._colors = {}
		if color and _stderr_supports_color():
			# The curses module has some str/bytes confusion in
			# python3.  Until version 3.2.3, most methods return
			# bytes, but only accept strings.  In addition, we want to
			# output these strings with the logging module, which
			# works with unicode strings.  The explicit calls to
			# unicode() below are harmless in python2 but will do the
			# right conversion in python 3.
			fg_color = (curses.tigetstr("setaf") or
						curses.tigetstr("setf") or "")
			if (3, 0) < sys.version_info < (3, 2, 3):
				fg_color = unicode_type(fg_color, "ascii")

			for levelno, code in colors.items():
				self._colors[levelno] = unicode_type(curses.tparm(fg_color, code), "ascii")
			self._normal = unicode_type(curses.tigetstr("sgr0"), "ascii")
		else:
			self._normal = ''

	def format(self, record):
		try:
			message = record.getMessage()
			assert isinstance(message, basestring_type)  # guaranteed by logging
			# Encoding notes:  The logging module prefers to work with character
			# strings, but only enforces that log messages are instances of
			# basestring.  In python 2, non-ascii bytestrings will make
			# their way through the logging framework until they blow up with
			# an unhelpful decoding error (with this formatter it happens
			# when we attach the prefix, but there are other opportunities for
			# exceptions further along in the framework).
			#
			# If a byte string makes it this far, convert it to unicode to
			# ensure it will make it out to the logs.  Use repr() as a fallback
			# to ensure that all byte strings can be converted successfully,
			# but don't do it by default so we don't add extra quotes to ascii
			# bytestrings.  This is a bit of a hacky place to do this, but
			# it's worth it since the encoding errors that would otherwise
			# result are so useless (and tornado is fond of using utf8-encoded
			# byte strings whereever possible).

			record.message = _safe_unicode(message)
		except Exception as e:
			record.message = "Bad message (%r): %r" % (e, record.__dict__)

		record.asctime = self.formatTime(record, self.datefmt)

		if record.levelno in self._colors:
			record.color = self._colors[record.levelno]
			record.end_color = self._normal
		else:
			record.color = record.end_color = ''

		if getattr(record, 'clientip', False):
			if isinstance(record.clientip, tuple):
				# record.clientip = '%s:%d' % record.clientip
				record.clientip = record.clientip[0]
			else:
				record.clientip = str(record.clientip)

		d = collections.defaultdict(lambda : str('\b'))
		d.update(record.__dict__)
		formatted = self._fmt % d

		if record.exc_info:
			if not record.exc_text:
				record.exc_text = self.formatException(record.exc_info)
		if record.exc_text:
			# exc_text contains multiple lines.  We need to _safe_unicode
			# each line separately so that non-utf8 bytes don't cause
			# all the newlines to turn into '\n'.
			lines = [formatted.rstrip()]
			lines.extend(_safe_unicode(ln) for ln in record.exc_text.split('\n'))
			formatted = '\n'.join(lines)
		return formatted.replace("\n", "\n    ")



def enable_pretty_logging(options=None, logger=None):
	"""Turns on formatted logging output as configured.

	This is called automatically by `tornado.options.parse_command_line`
	and `tornado.options.parse_config_file`.
	"""
	if options is None:
		from tornado.options import options
	if options.logging is None or options.logging.lower() == 'none':
		return
	if logger is None:
		logger = logging.getLogger()
	logger.setLevel(getattr(logging, options.logging.upper()))

	if options.log_file_prefix:
		channel = logging.handlers.RotatingFileHandler(
			filename=options.log_file_prefix,
			maxBytes=options.log_file_max_size,
			backupCount=options.log_file_num_backups)
		formatter = LogFormatter(color=False)
		channel.setFormatter(formatter)
		logger.addHandler(channel)

	if (options.log_to_stderr or
			(options.log_to_stderr is None and not logger.handlers)):
		channel = None
		if options.remoteArchive:
			from framework.nsq_log import NSQHandler
			channel = NSQHandler(logger.name)
		else:
			channel = logging.StreamHandler()
		# Set up color if we are in a tty and curses is installed
		formatter = LogFormatter()
		channel.setFormatter(formatter)
		logger.addHandler(channel)

def define_logging_options(options=None):
	if options is None:
		# late import to prevent cycle
		from tornado.options import options
	options.define("logging", default="info",
				   help=("Set the Python log level. If 'none', tornado won't touch the "
						 "logging configuration."),
				   metavar="debug|info|warning|error|none")
	options.define("log_to_stderr", type=bool, default=None,
				   help=("Send log output to stderr (colorized if possible). "
						 "By default use stderr if --log_file_prefix is not set and "
						 "no other logging is configured."))
	options.define("log_file_prefix", type=str, default=None, metavar="PATH",
				   help=("Path prefix for log files. "
						 "Note that if you are running multiple tornado processes, "
						 "log_file_prefix must be different for each of them (e.g. "
						 "include the port number)"))
	options.define("log_file_max_size", type=int, default=100 * 1000 * 1000,
				   help="max size of log files before rollover")
	options.define("log_file_num_backups", type=int, default=100,
				   help="number of log files to keep")

	# remoteArchive
	options.define("remoteArchive", type=bool, default=False,
				   help="send log to remote for archive")

	options.add_parse_callback(enable_pretty_logging)


class MyLoggerAdapter(logging.LoggerAdapter):

	def __init__(self, logger, **kwargs):
		logging.LoggerAdapter.__init__(self, logger, kwargs)

	def process(self, msg, kwargs):
		if 'extra' not in kwargs:
			extra = kwargs
			kwargs = {'extra' : kwargs}
			if 'exc_info' in extra:
				kwargs['exc_info'] = extra.pop('exc_info')
		else:
			extra = kwargs['extra']

		for k, v in self.extra.iteritems():
			if k not in extra:
				extra[k] = v
		return msg, kwargs

	def addKwargs(self, **kwargs):
		self.extra.update(kwargs)


# Logger objects for game
logger = None

def initLog(name, remoteArchive=True):
	global logger

	import tornado.options
	tornado.options.options = tornado.options.OptionParser()
	define_logging_options()
	# TODO: nsq开久了，CPU占用很高，晚点查
	# tornado.options.options.remoteArchive = remoteArchive
	# tornado.options.options.log_file_prefix = 'log_%s.log' % name

	# 只在自己层级打log，禁止copy到parent
	logger = MyLoggerAdapter(logging.getLogger(name))
	logger.logger.propagate = False
	enable_pretty_logging(logger=logger.logger)

	import tornado.log
	tornado.log.access_log = logger
	tornado.log.app_log = logger
	tornado.log.gen_log = logger

	import nsq.async
	import nsq.reader
	import nsq.writer
	import nsq.client
	nsq.async.logger = logger
	# nsq.client.logger = logger
	nsq.reader.logger = logger
	nsq.writer.logger = logger

	import nsqrpc.client
	import nsqrpc.server
	nsqrpc.client.logger = logger
	nsqrpc.server.logger = logger

def setLogPrefixName(name):
	global logger
	logger.logger.name = name


def setLogOptions(**kwargs):
	if 'topic' in kwargs:
		for hdlr in logger.logger.handlers:
			if hasattr(hdlr, 'setLogTopic'):
				hdlr.setLogTopic(kwargs['topic'])


# for test
if __name__ == '__main__':

	initLog('test')
	# , extra={'clientip' : '192.168.xxxx'}
	logger.info('你好xxxxx1111')
	logger.info('你好xxxxx2222')
	logger.info('你好xxxxx333', clientip = '192.168.xxxx')
	logger.info('你好xxxxx444')
	logger.addKwargs(clientip = '192.168.yyyy')
	logger.info('你好xxxxx5555')
	logger.info('你好xxxxx666', clientip = '192.168.zzzzzzz')
	logger.info('你好xxxxx777', xxx=123)
	logger.exception('你好xxxxx777', xxx=123)
	logger.error('你好xxxxx777', xxx=123)

	try:
		raise Exception('test')
	except:
		logger.exception('你好xxxxx777', xxx=123)

