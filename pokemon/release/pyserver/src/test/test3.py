#!/usr/bin/python
# -*- coding: utf-8 -*-

def itor2(i):
	yield i

def itor():
	i=0
	while True:
		g = itor2(i)
		yield g.next()
		i+=1

it=itor()
print it
print it.next()
print it.next()
