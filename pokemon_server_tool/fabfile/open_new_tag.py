#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
from fabric import *
from env import config

SVN_HOST = "192.168.1.125"
def login_shenhe_svn_up(c):
    def _svn_up():
        with c.forward_remote(local_port=3690, local_host=SVN_HOST, remote_port=3690):
            print c.original_host
            c.run('svn cleanup')
            c.run('svn revert shenhe.json')
            c.run('svn up shenhe.json')
            return c.run('svn info').stdout

    with c.cd('/mnt/release/login/conf'):
        try:
            _svn_up()
        except Exception, e:
            if str(e).find('TCP forwarding request denied') >= 0:
                ret = c.run('lsof -i:3690|grep sshd|awk \'{print $2}\'').stdout
                if len(ret.split()) > 1:
                    ret = ret.split()[0]
                if len(ret) > 0:
                    c.run('kill -9 %d' % int(ret))
                _svn_up()

roledefs = {
    'cn': 'tc-pokemon-cn-login',
    'en': 'tc-pokemon-en-login',
    'kr': 'tc-pokemon-kr-login',
    'tw': 'ks-pokemon-tw-login',
    'xy': 'xy-pokemon-cn-login',
}

if __name__ == '__main__':
    language = sys.argv[1]
    print 'language:', language
    c = Connection(roledefs[language], config=config)
    login_shenhe_svn_up(c)
