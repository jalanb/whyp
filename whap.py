"""This small script offers a python equivalent to "which"

For every argument on the command line it lists
    all python files and all directories with that name
    in each of the directories in sys.path

If a name is found more than once each is listed
    (but python will only import one, probably the first listed)
"""


from __future__ import print_function
import os
import sys
import argparse
import fnmatch
import importlib
from bdb import BdbQuit

try:
    import pudb as pdb
except ImportError:
    import pdb

__version__ = '1.1.0'


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
    """Whether that name is a file in path and matches that glob"""
    return is_file_in(path, name) and fnmatch.fnmatch(name, glob)


def path_to_module(path, name):
    """Whether the name matches a python source or compiled file in that path

    If source and compiled files are found, give the source
    """
    glob = '%s.py*' % name
    python_files = [f
                    for f in directory_list(path)
                    if is_matching_file_in(path, f, glob)]
    if not python_files:
        return None
    source_files = [f
                    for f in python_files
                    if os.path.splitext(f)[-1] == '.py']
    python_file = source_files and source_files[0] or python_files[0]
    return os.path.join(path, python_file)


def path_to_sub_directory(path, name):
    """If name is a real sub-directory of path, return that"""
    result = os.path.join(path, name)
    if os.path.isdir(result):
        return result


def path_to_python(path, name):
    """Path to either a module or sub-dir of that path, with that name"""
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


def run_args(args, methods):
    """Run any methods eponymous with args"""
    if not args:
        return False
    valuable_args = {k for k, v in args.__dict__.items() if v}
    arg_methods = {methods[a] for a in valuable_args if a in methods}
    for method in arg_methods:
        method(args)


def version(args):
    print('%s %s' % (args, __version__))
    raise SystemExit


def Use_debugger(_args):
    try:
        import pudb as pdb
    except ImportError:
        import pdb
    pdb.set_trace()


def parse_args(methods):
    """Parse out command line arguments"""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('modules', metavar='modules', type=str, nargs='+',
                        help='Python modules to be used')
    parser.add_argument('-e', '--edit', action='store_true',
                        help='Edit the files')
    parser.add_argument('-l', '--list', action='store_true',
                        help='List the files (ls -l)')
    parser.add_argument('-q', '--quiet', action='store_true',
                        help='Say nothing')
    parser.add_argument('-v', '--version', action='store_true',
                        help='Show version')
    parser.add_argument('-U', '--Use_debugger', action='store_true',
                        help='Run the script with pdb (or pudb if available)')
    args = parser.parse_args()
    run_args(args, methods)
    return args


from contextlib import contextmanager

@contextmanager
def look_here(name):
    here = os.getcwd()
    remove_here = False
    if not here in sys.path:
        sys.path.insert(0, here)
        remove_here = True
    yield
    if remove_here:
        sys.path.remove(here)


def path_to_import(string, quiet):
    with look_here(string):
        try:
            module = importlib.import_module(string)
        except ImportError as e:
            if not quiet:
                print(e, file=sys.stderr)
            return None
    if module:
        pyc = module.__file__
        if '.egg/' in pyc:
            return pyc.split('.egg/')[0] + '.egg'
        py = os.path.realpath(os.path.splitext(pyc)[0] + '.py')
        return py if os.path.isfile(py) else pyc
    return None


def script(args):
    paths = set()
    for module in args.modules:
        if built_in(module):
            print('builtin', module)
            continue
        path_to_imported_module = path_to_import(module, args.quiet)
        if path_to_imported_module:
            paths.add(path_to_imported_module)
    if args.edit:
        command = 'vim -p'
    elif args.list:
        command = 'ls -l'
    else:
        command = 'echo'
    paths = ' '.join(sorted([str(_) for _ in paths]))
    if not args.quiet:
        print(command, paths)
    return bool(paths)


def main():
    """Run the script"""
    try:
        args = parse_args(globals())
        return os.EX_OK if script(args) else not os.EX_OK
    except BdbQuit:
        pass
    except SystemExit as e:
        return e.code
    except Exception as e:  # pylint: disable=broad-except
        if __version__[0] < '1':
            raise
        print(e, sys.stderr)
        return not os.EX_OK
    return os.EX_OK


if __name__ == '__main__':
    sys.exit(main())
