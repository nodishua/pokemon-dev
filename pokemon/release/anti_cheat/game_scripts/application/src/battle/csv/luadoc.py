#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import re
import sys
import json
import datetime

FuncReg = "^function\s+(?P<fname>[\w:]+)\s*\((?P<fparams>.*)\)"

LinkTag = '@link'
ParamTag = '@param'
CommentTag = '@comment'
ReturnTag = '@return'

def listFiles(rootDir):
	list_dirs = os.walk(rootDir)
	list_ret = []
	for root, dirs, files in list_dirs:
		for f in files:
			if f.endswith(".lua"):
				list_ret.append(os.path.join(root, f))
	return list_ret


def docTag2Chs(line):
	return line.replace(ParamTag, '参数:').replace(CommentTag, '说明:').replace(ReturnTag, '返回值:').replace(LinkTag, '链接:')


def docWriteTXT(fp, d):
	docs = list(d.get('docs', []))
	for k, l in enumerate(docs):
		docs[k] = docTag2Chs(l)

	fp.write('\n\n')
	fp.write('\n'.join(docs))
	fp.write('{fname}({fparams})\n'.format(**d))


ParamsMDTableHeader = '''
| 参数名 | 类型 | 说明 |
| ------ | ---- | ---- |
'''


def docWriteMD(fp, d, link):
	docs = list(d.get('docs', []))
	fp.write('\n\n')
	fp.write('## {fname}\n'.format(**d))
	fparams = d['fparams']
	if fparams:
		fp.write('\n**参数表：(%s)**\n' % fparams)

	docs = [s[2:].strip() for s in docs]
	newdocs = []
	docTags = {}
	prevIsComment = False
	for s in docs:
		if s.find(ParamTag) >= 0:
			words = s.replace(ParamTag, '').strip().split(' ', 2)
			key, val = words[0], None
			if len(words) >= 3:
				# may be type
				if words[1].isalpha():
					val = words[1:]
				else:
					val = ('', ' '.join(words[1:]))
			elif len(words) >= 2:
				val = ('', words[1])
			if val:
				val = (val[0].strip(), val[1].strip())
				if val[0] is None and val[1] is None:
					val = None
			if val:
				docTags[key] = val
			continue
		elif s.find(ReturnTag) >= 0:
			docTags[ReturnTag] = s.replace(ReturnTag, '')
			continue
		elif s.find(CommentTag) >= 0:
			newdocs.append(s.replace(CommentTag, '> '))
			prevIsComment = True
			continue
		elif s.find(LinkTag) >= 0:
			data = s.split(' ')
			# docTags[LinkTag] = data[2]
			# fp.write('\n[%s](#%s)\n' % (data[2],data[2].lower().replace('_','').replace('.','')))
			newdocs.append('\n[%s](#%s)\n' % (data[2],data[2].lower().replace('_','').replace('.','')))
			if link.get(data[1]) == None:
				link[data[1]] = {}
			link[data[1]][data[2]] = True
			continue

		if prevIsComment:
			prevIsComment = False
			newdocs.append('')
		newdocs.append(s)
	fp.write('\n'.join(newdocs))
	fp.write('\n')

	if ReturnTag in docTags:
		fp.write('\n**返回值：%s**\n' % docTags[ReturnTag])
		del docTags[ReturnTag]
	# elif LinkTag in docTags:
	# 	fp.write('\n[%s](#%s)\n' % (docTags[LinkTag],docTags[LinkTag].lower().replace('_','').replace('.','')))
	# 	del docTags[LinkTag]

	if docTags:
		fp.write(ParamsMDTableHeader)
		paramNames = [s.strip() for s in fparams.split(',')]
		params = []
		for param in paramNames:
			typ, desc = '', ''
			if param in docTags:
				typ, desc = docTags[param]
				del docTags[param]
			s = ' | '.join((param, typ, desc))
			params.append('| %s |' % s)
		for key, val in docTags.iteritems():
			s = ' | '.join([key] + val)
			params.append('| %s |' % s)
		fp.write('\n'.join(params))

	fp.write('\n\n')

EnumMDTableHeader = '''
| 参数名 | 值 | 说明 |
| ------ | ---- | ---- |
'''

def docWriteLink(fp,link):
	for filename in link:
		print '=' * 10
		print 'file:', filename
		enumlist = link[filename]
		filename = "..\\..\\..\\..\\src\\%s" % filename
		fp.write("\n\n# %s\n\n" % filename)

		with open(filename, 'rb') as enumfp:
			data = enumfp.read()
		lines = data.split('\n')

		enumdict = {}
		readswitch = False

		for i, line in enumerate(lines):
			if line == '}\r':
				readswitch = False
			if readswitch and re.match(r'.*=.*,',line): # write info
				data = line.replace('\r','').split('=')
				argname = data[0]
				argname = argname.replace('--','(未启用)')
				data = data[1].split('--')
				argvalue = data[0].replace(',', '')
				if len(data) == 1:
					data.append('')
				argnote = data[1]
				fp.write('| %s | %s | %s |\r' % (argname, argvalue, argnote))
			else:
				for enumhead in enumlist:
					if enumhead in line:  # write head
						readswitch = True
						fp.write("## %s" % enumhead)
						fp.write(EnumMDTableHeader)
						del enumlist[enumhead]
						break



def main():
	files = []
	if len(sys.argv) > 1:
		files = sys.argv[1:]
	else:
		files = listFiles(".")

	fre = re.compile(FuncReg)
	fpDoc = open('doc.txt', 'wb')
	fpMD = open('doc.md', 'wb')

	fpMD.write("该文档生成于 %s\n\n" % datetime.datetime.now())
	fpMD.write("[TOC]\n\n")

	link = {}

	for filename in files:
		print '='*10
		print 'file:', filename

		fpMD.write("\n\n# %s\n\n" % filename)

		with open(filename, 'rb') as fp:
			data = fp.read()
		lines = data.split('\n')
		for i, line in enumerate(lines):
			match = fre.search(line)
			if not match:
				continue

			d = match.groupdict()
			j = i - 1
			isdoc = False
			while j >= 0 and lines[j][:2] == '--':
				j -= 1
				isdoc = True
			j = j + 1
			docs = lines[j:i]
			# print j, i, lines[j:i]
			if isdoc:
				d['docs'] = docs

			print '-'*10
			print match.group('fname')
			print match.group('fparams')
			docWriteTXT(fpDoc, d)
			docWriteMD(fpMD, d, link)

			if not docs:
				print '!!! lost doc', d

	docWriteLink(fpMD,link)

	fpDoc.close()
	fpMD.close()


if __name__ == '__main__':
	main()