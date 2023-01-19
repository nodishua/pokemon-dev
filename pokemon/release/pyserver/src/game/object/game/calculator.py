#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from game.object import AttrDefs

from contextlib import contextmanager
import numpy as np

zeros = lambda : np.zeros(AttrDefs.attrTotal + 1)
ones = lambda : np.ones(AttrDefs.attrTotal + 1)

def dict2attrs(d):
	v = zeros()
	for attr, val in d.iteritems():
		v[AttrDefs.attrs2Enum[attr]] = val
	return v

def attrs2dict(attrs):
	d = {}
	for i, v in enumerate(attrs):
		if i > 0:
			d[AttrDefs.attrsEnum[i]] = v
	return d

class Node(object):
	__slots__ = ('name', 'tag', 'value', 'parent', 'left', 'right', 'adds')

	def __init__(self, name, tag=None, parent=None, left=None, right=None, default=None):
		self.name = name
		self.tag = tag
		self.value = None
		self.parent = parent
		self.left = left
		self.right = right
		self.adds = {}
		if default is not None:
			self.set('default', default)

	def __str__(self):
		return '<Node object at 0x%x>\n%s: %s\n' % (id(self), self.name, tuple(self.value))

	def addLeft(self, node):
		self.left = node
		node.parent = self
		node.tag = 'l'
		return self

	def addRight(self, node):
		self.right = node
		node.parent = self
		node.tag = 'r'
		return self

	def set(self, k, v):
		if self.value is None:
			self.adds[k] = v
			return
		delta = v - self.adds.get(k, 0)
		if any(delta):
			self.adds[k] = v
			self.value += delta
			self.onchange(delta)

	def peek(self, k):
		v = self.adds.get(k)
		if v is not None:
			return v
		else:
			return zeros()

	# invoke by self
	def onchange(self, delta):
		if self.parent:
			self.parent.change(delta, self.tag)

	# invoke by child
	def change(self, delta, childtag):
		if self.value is None:
			return
		if self.name == '*':
			if childtag == 'l':
				delta = self.right.value * delta
			else:
				delta = self.left.value * delta
		if any(delta):
			self.value += delta
			self.onchange(delta)

	def evaluation(self):
		if self.value is None:
			if self.name == '+':
				self.value = self.left.evaluation() + self.right.evaluation()
			elif self.name == '*':
				self.value = self.left.evaluation() * self.right.evaluation()
			else:
				self.value = sum(self.adds.values())
		return self.value

	def display(self):
		f = []
		if self.name not in ('+', '*'):
			f.append('(')
			for k in self.adds.keys():
				f.append(k)
				f.append(' + ')
			f[-1] = ')'
		else:
			f.append(' ' + self.name + ' ')
		return ''.join(f)

	def to_dict(self):
		ret = []
		for key in sorted(self.adds.keys()):
			ret.append((key, tuple(self.adds[key])))
		return ret

class Calculator(object):

	def __init__(self):
		self._nodes = {}
		self._expression = self.expression()

	def __getattr__(self, name):
		try:
			return self._nodes[name]
		except KeyError:
			raise AttributeError("%s instance has no attribute '%s'" % (self.__class__.__name__, name))

	def expression(self):
		# 最终数值 = (基础值 * 性格百分比 * 个体值百分比 * 养成百分比加成) + 养成固定值加成
		base = Node('base')
		character = Node('character')
		nvalue = Node('nvalue', default=ones())
		percent = Node('percent', default=ones())
		const = Node('const')

		character.set('character', ones())

		self._nodes['base'] = base
		self._nodes['percent'] = percent
		self._nodes['const'] = const
		self._nodes['character'] = character
		self._nodes['nvalue'] = nvalue

		p1 = Node('*')
		p1.addLeft(base).addRight(character)

		p2 = Node('*')
		p2.addLeft(p1).addRight(nvalue)

		p3 = Node('*')
		p3.addLeft(p2).addRight(percent)

		p4 = Node('+')
		p4.addLeft(p3).addRight(const)

		return p4

	def evaluation(self):
		return attrs2dict(self._expression.evaluation())

	def display(self, detail=False):
		f = []
		def show(node, f):
			if node.name in ('+', '*'):
				f.append('(')
			if node.left:
				show(node.left, f)
			if detail:
				f.extend(node.display())
			else:
				f.append(' ' + node.name + ' ')
			if node.right:
				show(node.right, f)
			if node.name in ('+', '*'):
				f.append(')')
		show(self._expression, f)
		print ''.join(f[1:-1])

	def to_dict(self):
		ret = {
			'base': self.base.to_dict(),
			'character': self.character.to_dict(),
			'nvalue': self.nvalue.to_dict(),
			'percent': self.percent.to_dict(),
			'const': self.const.to_dict(),
		}
		return ret


@contextmanager
def temporary(calc, *args):
	s = []
	for key in args:
		const = calc.const.peek(key)
		percent = calc.percent.peek(key)
		s.append((key, const, percent))
	yield
	for key, const, percent in s:
		calc.const.set(key, const)
		calc.percent.set(key, percent)
