"""Show the text behind commands

This script is intended to replace the standard which command
It should look for commands in aliases, bash functions, and the bash $PATH
It assumes aliases and functions have been written to files before starting
	(because we cannot reliably get them from sub-shells called hence)

(c) J Alan Brogan 2013
	The source is released under the MIT license
	See http://jalanb.mit-license.org/ for more information
"""


import os
import re
import sys
import stat
import doctest
import optparse
import subprocess


def get_options():
	"""The values of options set by user on command line"""
	return None


def get_verbosity():
	"""Whether more info should be shown"""
	return False


def environment_value(key):
	"""A value from the shell environment, defaults to empty string

	>>> environment_value('_') == sys.executable
	True
	"""
	return os.environ.get(key, '')


class BashError(ValueError):
	"""Use this class to have a more appropriate name appear in tracebacks"""
	pass


class Bash:
	"""This class is a namespace to hold bash commands to be used later"""
	# pylint wants an __init__(), but I don't
	# pylint: disable-msg=W0232
	view_file = 'vat'  # This is my alias for https://github.com/vim-scripts/vimcat, YMMV
	declare_f = 'declare -f'  # This is a bash builtin
	ls = 'ls'  # This is often in path, and more often aliased


def replace_alias(command):
	"""Replace any alias with its value at start of the command"""
	if ' ' not in command:
		return command
	command, arguments = command.split(' ', 1)
	return '%s %s' % (get_alias(command), arguments)


def bash_executable():
	"""The first executable called 'bash' in the $PATH"""
	return files_in_environment_path()['bash']


def show_output_of_shell_command(command):
	"""Run the given command using bash"""
	command = replace_alias(command)
	bash_command = [bash_executable(), '-c', command]
	process = subprocess.Popen(bash_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	stdout, stderr = process.communicate()
	if not process.returncode:
		print stdout
		if get_options().hide_errors:
			return
		if not stderr:
			return
	raise BashError('''
	command: %r
	status: %s
	stderr: %s
	stdout: %s''' % (command, process.returncode, stderr, stdout))


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
	cache = []  # using a list to workaround some flagrant warnings from pylint
	def new_method():
		if not cache:
			cache.append(method())
		return cache[0]
	new_method.__doc__ = method.__doc__
	new_method.__name__ = 'memoized_%s' % method.__name__
	return new_method


@memoize
def get_aliases():
	"""Read a dictionary of aliases from a file"""
	lines = [l.rstrip() for l in file(get_options().aliases)]
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
	lines = [l.rstrip() for l in file(get_options().functions)]
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
	"""A list of paths in the environment's PATH

	>>> '/bin' in environment_paths()
	True
	"""
	return environment_value('PATH').split(':')


def contractuser(path):
	"""Replace the home directory in that path with ~

	This is the opposite of os.path.expanduser()

	>>> contractuser(os.path.expanduser('~/.bashrc')) == '~/.bashrc'
	True
	"""
	home_symbol = '~'
	home = os.path.expanduser(home_symbol)
	if path.startswith(home):
		return path.replace(home, home_symbol)
	return path


def items_in(path):
	"""A list of all items in the given path

	>>> '/usr/local' in items_in('/usr')
	True
	"""
	try:
		return [(name, os.path.join(path, name)) for name in os.listdir(path)]
	except OSError:
		return []


def files_in(path):
	"""A list of all files in the given path

	>>> '/bin/bash' in files_in('/bin')
	True
	"""
	return [(f, p) for (f, p) in items_in(path) if os.path.isfile(p)]


def is_executable(path_to_file):
	"""Whether the file has any executable bits set

	>>> is_executable(sys.executable)
	True
	"""
	executable_bits = stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH
	try:
		return bool(os.stat(path_to_file).st_mode & executable_bits)
	except OSError:
		return False


def executables_in(path):
	"""A list of all executable files in the given path"""
	return [(f, p) for (f, p) in items_in(path) if is_executable(p)]


@memoize
def files_in_environment_path():
	"""Gives a dictionary of all executable files in the shell environment's PATH

	>>> files_in_environment_path()['python'] == sys.executable
	True
	"""
	result = set([])
	for path in environment_paths():
		for filename, path_to_file in executables_in(path):
			result.add((filename, path_to_file))
	return dict(result)


def shown_languages():
	"""A list of languages whose source files we are interested in viewing"""
	return ['python', 'bash', 'sh']


def show_function(command):
	"""Show a function to the user"""
	show_output_of_shell_command(". %s; %s %s  | sed '1 i\\\n#! /bin/bash\n' | %s" % (
		get_options().functions, Bash.declare_f, command, Bash.view_file))


def shebang_command(path_to_file):
	"""Get the shebang line of that file

	Which is the first line, if that line starts with #!
	"""
	try:
		first_line = file(path_to_file).readlines()[0]
		if first_line.startswith('#!'):
			return first_line[2:].strip()
	except (IndexError, IOError):
		pass
	return ''


def extension_language(path_to_file):
	"""Guess the language used to run a file from its extension"""
	_, extension = os.path.splitext(path_to_file)
	known_languages = {'.py': 'python', '.sh': 'bash'}
	return known_languages.get(extension, None)


def shebang_language(path_to_file):
	"""Guess the language used to run a file from its shebang line"""
	run_command = shebang_command(path_to_file)
	command_words = re.split('[ /]', run_command)
	try:
		last_word = command_words
	except IndexError:
		last_word = None
	return last_word


def script_language(path_to_file):
	"""Guess the language used to run a file from its first line

	The language should be the last word on the shebang line (if present)
	If no shebang line is found, try an extension

	>>> script_language('what.py') == 'python' and script_language('script.sh') == 'bash'
	True
	"""
	for get_language in [shebang_command, extension_language]:
		language = get_language(path_to_file)
		if language:
			return language


def show_command_in_path(command):
	"""Show a command which is a file in $PATH"""
	path_to_command = files_in_environment_path()[command]
	show_output_of_shell_command('%s -l %r' % (Bash.ls, path_to_command))
	if not get_options().verbosity:
		return
	if script_language(path_to_command) in shown_languages():
		show_output_of_shell_command('%s %r' % (Bash.view_file, str(path_to_command)))


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
	if command in files_in_environment_path():
		show_command_in_path(command)
	return 0


def nearby_file(extension):
	"""Return the name of this module, changed to use that extension

	>>> os.path.basename(nearby_file('.txt')) == 'what.txt'
	True
	"""
	return os.path.splitext(__file__)[0] + extension


def read_command_line():
	"""Look for options from user on the command line for this script"""
	parser = optparse.OptionParser('Usage: what [options] command\n\n%s' % __doc__)
	parser.add_option('-a', '--aliases', help='path to file which holds aliases', default='/tmp/aliases')
	parser.add_option('-e', '--hide_errors', help='hide error messages from commands with successful status', action='store_true')
	parser.add_option('-f', '--functions', help='path to file which holds functions', default='/tmp/functions')
	parser.add_option('-v', '--verbose', help='whether to show more info, such as file contents', action='store_true')
	options, args = parser.parse_args()
	# plint does not seem to notice that methods are globals
	# pylint: disable-msg=W0601
	global get_options
	get_options = lambda: options
	return args


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


def main():
	"""Run the program"""
	args = read_command_line()
	result = 0
	for arg in args:
		result |= show_command(arg)
	return result


if __name__ == '__main__':
	if len(sys.argv) == 1:
		sys.exit(test())
	else:
		sys.exit(main())
