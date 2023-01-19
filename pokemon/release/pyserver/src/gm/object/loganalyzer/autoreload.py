#!/usr/bin/env python
#
# Copyright 2009 Facebook
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

"""Automatically restart the server when a source file is modified.

Most applications should not access this module directly.  Instead,
pass the keyword argument ``autoreload=True`` to the
`tornado.web.Application` constructor (or ``debug=True``, which
enables this setting and several others).  This will enable autoreload
mode as well as checking for changes to templates and static
resources.  Note that restarting is a destructive operation and any
requests in progress will be aborted when the process restarts.  (If
you want to disable autoreload while using other debug-mode features,
pass both ``debug=True`` and ``autoreload=False``).

This module can also be used as a command-line wrapper around scripts
such as unit test runners.  See the `main` method for details.

The command-line wrapper and Application debug modes can be used together.
This combination is encouraged as the wrapper catches syntax errors and
other import-time failures, while debug mode catches changes once
the server has started.

This module depends on `.IOLoop`, so it will not work in WSGI applications
and Google App Engine.  It also will not work correctly when `.HTTPServer`'s
multi-process mode is used.

Reloading loses any Python interpreter command-line arguments (e.g. ``-u``)
because it re-executes Python using ``sys.executable`` and ``sys.argv``.
Additionally, modifying these variables will cause reloading to behave
incorrectly.

"""

from __future__ import absolute_import, division, print_function, with_statement

import os
import sys

# sys.path handling
# -----------------
#
# If a module is run with "python -m", the current directory (i.e. "")
# is automatically prepended to sys.path, but not if it is run as
# "path/to/file.py".  The processing for "-m" rewrites the former to
# the latter, so subsequent executions won't have the same path as the
# original.
#
# Conversely, when run as path/to/file.py, the directory containing
# file.py gets added to the path, which can cause confusion as imports
# may become relative in spite of the future import.
#
# We address the former problem by setting the $PYTHONPATH environment
# variable before re-execution so the new process will see the correct
# path.  We attempt to address the latter problem when tornado.autoreload
# is run as __main__, although we can't fix the general case because
# we cannot reliably reconstruct the original command line
# (http://bugs.python.org/issue14208).

if __name__ == "__main__":
	# This sys.path manipulation must come before our imports (as much
	# as possible - if we introduced a tornado.sys or tornado.os
	# module we'd be in trouble), or else our imports would become
	# relative again despite the future import.
	#
	# There is a separate __main__ block at the end of the file to call main().
	if sys.path[0] == os.path.dirname(__file__):
		del sys.path[0]

import functools
import logging
import os
import pkgutil
import sys
import traceback
import types
import subprocess
import weakref

from tornado import ioloop
from tornado.log import gen_log
from tornado import process
from tornado.util import exec_in

try:
	import signal
except ImportError:
	signal = None


_watched_dir = '.'
_watched_files = set()
_reload_hooks = []
_reload_attempted = False
_io_loops = weakref.WeakKeyDictionary()


def start(files_dir='.', io_loop=None, check_time=1000):
	"""Begins watching source files for changes.

	.. versionchanged:: 4.1
	   The ``io_loop`` argument is deprecated.
	"""
	io_loop = io_loop or ioloop.IOLoop.current()
	if io_loop in _io_loops:
		return
	_io_loops[io_loop] = True
	if len(_io_loops) > 1:
		gen_log.warning("tornado.autoreload started more than once in the same process")
	global _watched_dir
	_watched_dir = files_dir
	modify_times = {}
	callback = functools.partial(_reload_on_update, modify_times)
	scheduler = ioloop.PeriodicCallback(callback, check_time, io_loop=io_loop)
	scheduler.start()


def wait():
	"""Wait for a watched file to change, then restart the process.

	Intended to be used at the end of scripts like unit test runners,
	to run the tests again after any source file changes (but see also
	the command-line interface in `main`)
	"""
	io_loop = ioloop.IOLoop.current()
	io_loop.start()


def watch(filename):
	"""Add a file to the watch list.

	All imported modules are watched by default.
	"""
	_watched_files.add(filename)


def add_reload_hook(fn):
	"""Add a function to be called before reloading the process.

	Note that for open file and socket handles it is generally
	preferable to set the ``FD_CLOEXEC`` flag (using `fcntl` or
	``tornado.platform.auto.set_close_exec``) instead
	of using a reload hook to close them.
	"""
	_reload_hooks.append(fn)


def _reload_on_update(modify_times):
	if _reload_attempted:
		# We already tried to reload and it didn't work, so don't try again.
		return
	if process.task_id() is not None:
		# We're in a child process created by fork_processes.  If child
		# processes restarted themselves, they'd all restart and then
		# all call fork_processes again.
		return
	# list files in directory
	list_dirs = os.walk(_watched_dir)
	list_ret = []
	for root, dirs, files in list_dirs:
		for f in files:
			if f.endswith('.log'):
				list_ret.append(os.path.join(root, f))
	for path in list_ret:
		_check_file(modify_times, path)
	for path in _watched_files:
		_check_file(modify_times, path)


def _check_file(modify_times, path):
	try:
		modified = os.stat(path).st_mtime
	except Exception:
		return
	if path not in modify_times or modify_times[path] != modified:
		modify_times[path] = modified
		_reload(path)


def _reload(path):
	global _reload_attempted
	_reload_attempted = True
	for fn in _reload_hooks:
		fn(path)
	_reload_attempted = False


if __name__ == '__main__':
	import time

	def test(path):
		print(time.time())
		with open(path, 'rb') as f:
			data = f.read()
		print(data)

	add_reload_hook(test)
	start()
	print('wait----', time.time())

	wait()
