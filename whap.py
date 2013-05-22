"""This small script offers a python equivalent to "which"

For every argument on the command line it lists
	all python files and all directories with that name
	in each of the directories in sys.path

If a name is found more than once each is listed
	(but python will only import one, probably the first listed)
"""

_copyright = """
(c) J Alan Brogan 2013
	The source is released under the MIT license
	See http://jalanb.mit-license.org/ for more information
"""


import os
import sys
import fnmatch


def directory_list(path):
	"""A list of all items in that path

	If path is not a directory, an empty list
	"""
	if not os.path.isdir(path):
		return []
	return os.listdir(path)


def is_file_in(path, name):
	"""Whether that name is a file in the directory at that path"""
	path_to_name = os.path.join(path, name)
	return os.path.isfile(path_to_name)


def is_matching_file_in(path, name, glob):
	"""Whether that name is a file in the directory at that path and matches that glob"""
	return is_file_in(path, name) and fnmatch.fnmatch(name, glob)


def path_to_module(path, name):
	"""Whether the name matches a python source or compiled file in the given path

	If source and compiled files are found, give the source
	"""
	glob = '%s.py*' % name
	python_files = [f for f in directory_list(path) if is_matching_file_in(path, f, glob)]
	if not python_files:
		return None
	source_files = [f for f in python_files if os.path.splitext(f)[-1] == '.py']
	python_file = source_files and source_files[0] or python_files[0]
	return os.path.join(path, python_file)


def path_to_sub_directory(path, name):
	"""If name is a real sub-directory of path, return that"""
	result = os.path.join(path, name)
	if os.path.isdir(result):
		return result


def path_to_python(path, name):
	"""Path to either a module or sub-dir of the given path, withthe given name"""
	result = path_to_sub_directory(path, name)
	if result:
		return result
	return path_to_module(path, name)


def built_in(name):
	"""Whether the name is that of one of python's builtin modules"""
	try:
		#  Not all builtin modules are initially imported, so bring it in first
		__import__(name)
	except ImportError:
		return False
	return '(built-in)' in str(sys.modules[name])


def main(strings):
	"""Run the program"""
	for string in strings:
		if built_in(string):
			print 'builtin', string
		for path in sys.path:
			path_to_string = path_to_python(path, string)
			if path_to_string:
				os.system('ls -ld %s' % path_to_string)


if __name__ == '__main__':
	args = sys.argv[1:]
	if not args:
		from what import test
		sys.exit(test())
	else:
		sys.exit(main(args))
