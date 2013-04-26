"""This small script offers a python equivalent to "which"

For every argument on the command line it displays
	all python files and all directories with that name
	in each of the directories in sys.path
"""

_copyright = """
(c) J Alan Brogan 2013
	The source is released under the MIT license
	See http://jalanb.mit-license.org/ for more information
"""


import os
import sys

def main():
	for arg in sys.argv[1:]:
		for path in sys.path:
			path_to_item = os.path.join(path, arg)
			if os.path.isdir(path_to_item):
				os.system('ls -ld %s' % path_to_item)
			else:
				path_to_python = os.path.join(path, '%s.py' % arg)
				if os.path.isfile(path_to_python):
					os.system('ls -l %s' % path_to_python)
	return 0


if __name__ == '__main__':
	sys.exit(main())
