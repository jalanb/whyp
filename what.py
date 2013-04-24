"""Show the text behind commands

This script is intended to replace the standard which command
It should look for commands in aliases, bash functions, and the bash $PATH
It assumes aliases and functions have been written to files before starting
	(because we cannot reliably get them from sub-shells called hence)

(c) J Alan Brogan 2013
	This source file is released under the MIT license
	See http://jalanb.mit-license.org/ for more information


This script has been tested
	on OSX using python 2.5, 2.6 and 2.7 and bash 3.2.48
	on CentOS using python 2.4 and 2.7 and bash 3.2.25
	on Ubuntu 10.04 using python 2.7 and bash

"""


import os
import re
import sys
import stat
import commands
import doctest


def path_to_aliases():
	"""The aliases have been written to this file before this script starts"""
	return '/tmp/aliases'


def path_to_functions():
	"""The functions have been written to this file before this script starts"""
	return '/tmp/functions'


def environment_value(key):
	"""A value from the bash environment, defaults to empty string

	>>> environment_value('_') == sys.executable
	True
	"""
	return os.environ.get(key, '')


class Bash:
	"""This class is a namespace to hold bash commands to be used later"""
	# pylint: disable-msg=W0232
	view_file = 'vat'  # This is my alias for https://github.com/vim-scripts/vimcat, YMMV
	declare_f = 'declare -f'  # This is a bash builtin
	ls = 'ls'  # This is often in path, and more often aliased


def run_bash_command(command):
	"""Run the given command"""
	if ' ' in command:
		command, arguments = command.split(' ', 1)
	else:
		arguments = ''
	command = '%s %s' % (get_alias(command), arguments)
	status, output = commands.getstatusoutput(command)
	if status == 0:
		print output
		return True
	raise ValueError(output)


def strip_quotes(string):
	"""Remove quotes from front and back of string

	>>> strip_quotes('"fred"') == 'fred'
	True
	"""
	if not string:
		return string
	first = string[0]
	last = string[-1]
	if first == last and first in '"\'':
		return string[1:-1]
	return string


def memoize(method):
	"""Cache the return value of the method, which takes no arguments"""
	cache = []
	def new_method():
		if not cache:
			cache.append(method())
		return cache[0]
	new_method.__doc__ = method.__doc__
	new_method.__name__ = 'memoized_%s' % method.__name__
	return new_method


@memoize
def get_aliases():
	"""Read a dictionary of aliases read from a known file"""
	lines = [l.rstrip() for l in file(path_to_aliases())]
	alias_lines = [l[6:] for l in lines if l.startswith('alias ')]
	alias_strings = [l.split('=', 1) for l in alias_lines]
	alias_commands = [(name, strip_quotes(command)) for (name, command) in alias_strings]
	return dict(alias_commands)


def get_alias(string):
	"""Give the alias for that string, or the string itself"""
	return get_aliases().get(string, string)


@memoize
def get_functions():
	"""Read a dictionary of functions from a known file"""
	lines = [l.rstrip() for l in file(path_to_functions())]
	name = function_lines = None
	functions = {}
	for line in lines:
		if line == '{':
			continue
		elif line == '}':
			functions[name] = function_lines[:]
		else:
			words = line.split()
			if not words:
				continue
			if len(words) == 2 and words[1] == '()':
				name = words[0]
				function_lines = []
				continue
			function_lines.append(line)
	result = {}
	for name, lines in functions.iteritems():
		result[name] = '%s ()\n{\n%s\n}\n' % (name, '\n'.join(lines))
	return result


def environment_paths():
	"""A list of path in the environment's PATH

	>>> '/bin' in environment_paths()
	True
	"""
	return environment_value('PATH').split(':')


def items_in(path):
	"""A list of all items in the given path

	>>> '/usr/local' in items_in('/usr')
	True
	"""
	try:
		return [os.path.join(path, name) for name in os.listdir(path)]
	except OSError:
		return []


def files_in(path):
	"""A list of all files in the given path

	>>> '/bin/bash' in files_in('/bin')
	True
	"""
	return [f for f in items_in(path) if os.path.isfile(f)]


def is_executable(path_to_file):
	"""Whether the file has any executable bits set

	>>> is_executable(sys.executable)
	True
	"""
	executable_bits = stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH
	return bool(os.stat(path_to_file).st_mode & executable_bits)


@memoize
def files_in_bash_path():
	"""Gives a dictionary of all executable files in the bash PATH

	>>> files_in_bash_path()['python'] == sys.executable
	True
	"""
	result = {}
	for path in environment_paths():
		for path_to_file in files_in(path):
			filename = os.path.basename(path_to_file)
			if filename in result:
				continue
			if is_executable(path_to_file):
				result[filename] = path_to_file
	return result


def shown_languages():
	"""A list of languages which we are interested in viewing directly"""
	return ['python', 'bash']


def show_function(command):
	"""Show a function to the user"""
	run_bash_command(". %s; %s %s  | sed '1 i\\\n#! /bin/bash\n' | %s" % (
		path_to_functions(), Bash.declare_f, command, Bash.view_file))


def shebang(path_to_file):
	"""Guess the language used to run a file from its first line"""
	try:
		first_line = file(path_to_file).readlines()[0]
		if first_line.startswith('#!'):
			return first_line[2:].strip()
	except (IndexError, IOError):
		pass
	return ''


def script_language(path_to_file):
	"""Guess the language used to run a file from its first line

	The language should be the last word on the shebang line (if present)
	If no shebang line is found, try an extension

	>>> script_language('what.py') == 'python' and script_language('script.sh') == 'bash'
	True
	"""
	run_command = shebang(path_to_file)
	if run_command:
		try:
			return re.split('[ /]', run_command)[-1]
		except IndexError:
			pass
	known_extensions = {'.py': 'python', '.sh': 'bash'}
	_, extension = os.path.splitext(path_to_file)
	return known_extensions.get(extension, '')


def show_command_in_path(command):
	"""Show a command which is a file in $PATH"""
	path_to_command = files_in_bash_path()[command]
	run_bash_command('%s -l %r' % (Bash.ls, path_to_command))
	if script_language(path_to_command) in shown_languages():
		run_bash_command('%s %r' % (Bash.view_file, str(path_to_command)))


def show_command(command):
	"""Show the text behind a command"""
	aliases = get_aliases()
	if command in aliases:
		print 'alias %s=%r' % (command, aliases[command])
		sub_command = aliases[command].split()[0].strip()
		if os.path.dirname(sub_command) in environment_paths():
			show_command(os.path.basename(sub_command))
		else:
			show_command(sub_command)
	if command in get_functions():
		show_function(command)
	if command in files_in_bash_path():
		show_command_in_path(command)
	return 0


def nearby_file(extension):
	"""Return the name of this module, changed to use that extension

	>>> os.path.basename(nearby_file('.txt')) == 'what.txt'
	True
	"""
	return os.path.splitext(__file__)[0] + extension


def test():
	"""Run any doctests in this script or associated test scripts"""
	options = doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE
	failures, _ = doctest.testmod(
		sys.modules[__name__],
		optionflags=options,
	)
	for extension in ['.test', '.tests']:
		failures, _ = doctest.testfile(
			nearby_file(extension),
			optionflags=options,
			module_relative=False,
		)
		if failures:
			return failures
	return 0


def main(words):
	"""Run the program"""
	result = 0
	for word in words:
		result |= show_command(word)
	return result


if __name__ == '__main__':
	args = sys.argv[1:]
	if not args:
		sys.exit(test())
	else:
		sys.exit(main(args))
