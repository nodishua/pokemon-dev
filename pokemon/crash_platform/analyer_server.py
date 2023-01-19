#!/usr/bin/python
# -*- coding: utf-8 -*-
import tornado.options
from analyprocess.server import Server

from multiprocessing import Queue

def main():
	tornado.options.define("name", default="crash_platform", help="server name", type=str)
	tornado.options.parse_command_line()
	fileServer = Server(tornado.options.options.name, Queue(1))
	fileServer.start()


if __name__ == "__main__":
	main()