#!/usr/bin/python
# -*- coding: utf-8 -*-


class DoubleLinkNode(object):
	def __init__(self, val):
		self.prev = None
		self.next = None
		self.val = val


class DoubleLinkList(object):
	def __init__(self, lst=None, cls=None):
		self.head = None
		self.tail = None
		self.len = 0
		self.cls = cls if cls else DoubleLinkNode
		if lst:
			for t in lst:
				self.append_tail(t)

	def append_tail(self, val=None, node=None):
		node = node if node else self.cls(val)
		if self.head is None:
			self.head = self.tail = node
			node.next = node.prev = None
		else:
			self.tail.next = node
			node.prev = self.tail
			node.next = None
			self.tail = node
		self.len += 1
		return node

	def append_head(self, val=None, node=None):
		node = node if node else self.cls(val)
		if self.head is None:
			self.head = self.tail = node
			node.next = node.prev = None
		else:
			self.head.prev = node
			node.prev = None
			node.next = self.head
			self.head = node
		self.len += 1
		return node

	def insert(self, parent, node):
		if parent == self.tail:
			self.append_tail(node=node)
		else:
			# assert parent.next is not None
			tmp = parent.next
			parent.next = node
			node.prev, node.next = parent, tmp
			tmp.prev = node
			self.len += 1

	def remove(self, node):
		if node == self.tail:
			self.tail = node.prev
			if self.tail is None:
				self.head = None
			else:
				self.tail.next = None
		elif node == self.head:
			self.head = node.next
			self.head.prev = None
		else:
			node.next.prev, node.prev.next = node.prev, node.next
		node.next = node.prev = None
		self.len -= 1

	def clear(self):
		# for gc
		tmp = self.head
		while tmp:
			tmp2 = tmp
			tmp = tmp.next
			tmp2.prev = tmp2.next = None
		self.head = self.tail = None
		self.len = 0

	def p(self):
		ret = []
		tmp = self.head
		while tmp:
			ret.append(tmp.val)
			tmp = tmp.next
		print ret

	def equal(self, l):
		tmp = self.head
		for n in l:
			if n != tmp.val:
				return False
			tmp = tmp.next
		if tmp is not None:
			return False

		tmp = self.tail
		for n in reversed(l):
			if n != tmp.val:
				return False
			tmp = tmp.prev
		if tmp is not None:
			return False

		return True


if __name__ == '__main__':
	T = 100
	ll = DoubleLinkList([i for i in xrange(T)])
	l2 = [i for i in xrange(T)]
	import random
	s = random.randint(0, 10000)
	s = 1062
	random.seed(s)

	for i in xrange(100):
		p = random.choice(l2)
		p2 = random.choice(l2)
		while p == p2:
			p = random.choice(l2)
		n = T + i
		r = random.randint(0, 2)
		if r == 0:
			print 'new insert', p, n
			l2.insert(l2.index(p)+1, n)
			pp = ll.head
			while pp:
				if pp.val == p:
					ll.insert(pp, DoubleLinkNode(n))
					break
				pp = pp.next
		elif r == 1:
			print 'remove', p
			l2.remove(p)
			pp = ll.head
			while pp:
				if pp.val == p:
					ll.remove(pp)
					break
				pp = pp.next
		elif r == 2:
			print 'old insert', p, p2
			l2.remove(p2)
			i1 = l2.index(p)
			l2.insert(i1+1, p2)


			pp2 = None
			pp = ll.head
			while pp:
				if pp.val == p2:
					ll.remove(pp)
					pp2 = pp
					break
				pp = pp.next

			pp = ll.head
			while pp:
				if pp.val == p:
					ll.insert(pp, pp2)
					break
				pp = pp.next
			

		# ll.p()
		# print l2
		
		if not ll.equal(l2):
			print '-'*20, i, p, n
			ll.p()
			print l2
			print 'seed', s
			assert False

	print ll.equal(l2)
