#!/usr/bin/python
# -*- coding: utf-8 -*-

from contextlib import contextmanager
import coverage
import sys

cov = coverage.Coverage()
@contextmanager
def code_coverage():
	# cov = coverage.Coverage()
	# cov.config.plugins.append('framework.code_coverage')
	cov.start()
	yield
	cov.stop()

def html_report():
	cov.save()
	cov.report()
	cov.html_report()

def tj_coverage(func):
	def wrapper(*args, **kwargs):
		cov.start()
		resp = func(*args, **kwargs)
		cov.stop()
		return resp
	return wrapper

class FileTracer(coverage.FileTracer):

	def __init__(self, filename):
		self.filename = filename

	def source_filename(self):
		return self.filename

class FileReporter(coverage.FileReporter):

	def lines(self):
		return set([x for x in xrange(1, 13)])

class Plugin(coverage.CoveragePlugin):

	def file_tracer(self, filename):
		print 'file_tracer', filename
		if 'test_code_coverage' in filename:
			print filename
			return FileTracer(filename)

		return None

	def file_reporter(self, filename):
		print 'file_reporter', filename

		return FileReporter(filename)


# def coverage_init(reg, options):
# 	reg.add_file_tracer(Plugin())
