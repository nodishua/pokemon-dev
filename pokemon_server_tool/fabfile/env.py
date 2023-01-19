#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2019 TianJi Information Technology Inc.
'''

import os

from fabric import Config

class _AttributeDict(dict):
    """
    Dictionary subclass enabling attribute lookup/assignment of keys/values.

    For example::

        >>> m = _AttributeDict({'foo': 'bar'})
        >>> m.foo
        'bar'
        >>> m.foo = 'not bar'
        >>> m['foo']
        'not bar'

    ``_AttributeDict`` objects also provide ``.first()`` which acts like
    ``.get()`` but accepts multiple keys as arguments, and returns the value of
    the first hit, e.g.::

        >>> m = _AttributeDict({'foo': 'bar', 'biz': 'baz'})
        >>> m.first('wrong', 'incorrect', 'foo', 'biz')
        'bar'

    """
    def __getattr__(self, key):
        try:
            return self[key]
        except KeyError:
            # to conform with __getattr__ spec
            raise AttributeError(key)

    def __setattr__(self, key, value):
        self[key] = value

    def first(self, *names):
        for name in names:
            value = self.get(name)
            if value:
                return value


default_port = '22'
default_ssh_config_path = os.path.join(os.path.expanduser('~'), '.ssh', 'config')

# Global environment dict. Currently a catchall for everything: config settings
# such as global deep/broad mode, host lists, username etc.
# Most default values are specified in `env_options` above, in the interests of
# preserving DRY: anything in here is generally not settable via the command
# line.
env = _AttributeDict({
    'abort_exception': None,
    'again_prompt': 'Sorry, try again.',
    'all_hosts': [],
    'combine_stderr': True,
    'colorize_errors': False,
    'command': None,
    'command_prefixes': [],
    'cwd': '',  # Must be empty string, not None, for concatenation purposes
    'dedupe_hosts': True,
    'default_port': default_port,
    'eagerly_disconnect': False,
    'echo_stdin': True,
    'effective_roles': [],
    'exclude_hosts': [],
    'gateway': None,
    'gss_auth': None,
    'gss_deleg': None,
    'gss_kex': None,
    'host': None,
    'host_string': None,
    'lcwd': '',  # Must be empty string, not None, for concatenation purposes
    'local_user': 'root',
    'output_prefix': True,
    'passwords': {},
    'path': '',
    'path_behavior': 'append',
    'port': default_port,
    'real_fabfile': None,
    'remote_interrupt': None,
    'roles': [],
    'roledefs': {},
    'shell_env': {},
    'skip_bad_hosts': False,
    'skip_unknown_tasks': False,
    'ssh_config_path': default_ssh_config_path,
    'sudo_passwords': {},
    'ok_ret_codes': [0],     # a list of return codes that indicate success
    # -S so sudo accepts passwd via stdin, -p with our known-value prompt for
    # later detection (thus %s -- gets filled with env.sudo_prompt at runtime)
    'sudo_prefix': "sudo -S -p '%(sudo_prompt)s' ",
    'sudo_prompt': 'sudo password:',
    'sudo_user': None,
    'tasks': [],
    'prompts': {},
    'use_exceptions_for': {'network': False},
    'use_shell': True,
    'use_ssh_config': False,
    'user': None,
    'version': 'test',
    'always_use_pty': False,
    'key_filename': None,
    'no_agent': True,
})



####################
# tianji env
print os.getcwd()
env.use_ssh_config = True
env.forward_agent = True
env.ssh_config_path = './ssh_config'
env.user = 'root'
env.password = '123456'
env.sudo_user = 'root'
env.sudo_password = '123456'
env.timeout = 10
env.warn_only = True

# http://docs.fabfile.org/en/latest/concepts/configuration.html#fab-configuration
config = Config.from_v1(env)
