"""This small script offers a python equivalent to "which"

For every argument on the command line it lists
    all python files and all directories with that name
    in each of the directories in sys.path

If a name is found more than once each is listed
    (but python will only import one, probably the first listed)
"""


import os
try:
    from io import StringIO
except ImportError:
    from six.moves import StringIO
import sys
import argparse
import fnmatch
import importlib
from bdb import BdbQuit
from contextlib import contextmanager

from six import StringIO
from pysyte import paths

from whyp import __version__
from whyp import arguments


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
        return os.path.normpath(result)


def path_to_python(path, name):
    """Path to either a module or sub-dir of that path, with that name"""
    result = path_to_sub_directory(path, name)
    if result:
        return result
    return path_to_module(path, name)


@contextmanager
def swallow_stdout_stderr():
    """Divert stdout into the given stream """
    saved_out = sys.stdout
    saved_err = sys.stderr
    sys.stdout = StringIO()
    sys.stderr = StringIO()
    try:
        yield
    finally:
        sys.stdout = saved_out
        sys.stderr = saved_err


def built_in(name):
    """Whether the name is that of one of python's builtin modules"""
    try:
        #  Not all builtin modules are initially imported, so bring it in first
        with swallow_stdout_stderr():
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
    print(__version__)
    raise SystemExit


@contextmanager
def look_here(_name):
    here = os.getcwd()
    remove_here = False
    if here not in sys.path:
        sys.path.insert(0, here)
        remove_here = True
    yield
    if remove_here:
        sys.path.remove(here)


def path_to_import(string, quiet):
    with look_here(string):
        try:
            with swallow_stdout_stderr():
                module = importlib.import_module(string)
        except ImportError as e:
            if not quiet:
                sys.stderr.write('%s\n' % string)
            return None, None
    if module:
        pyc = module.__file__
        if '.egg/' in pyc:
            dirname = pyc.split('.egg/')[0] + '.egg'
            name = os.path.basename(dirname)
            version_ = name.split('-')[1]
            return dirname, version_
        py = os.path.realpath(os.path.splitext(pyc)[0] + '.py')
        filename = py if os.path.isfile(py) else pyc
        try:
            return filename, module.__version__
        except AttributeError:
            return filename, None
    return None, None


def show(*args):
    string = ' '.join(args)
    if arguments.get('quiet'):
        return False
    print(string)
    return True


def module_paths(modules):
    strings = []
    for name, path, version in modules:
        item = None
        path_ = paths.makepath(path)
        if path_.ext != '.egg':
            item = path_
        else:
            dir_ = path_ / name
            if not dir_.isdir():
                item = dir_
            else:
                init = dir_ / '__init__.py'
                if init.isfile():
                    item = init
                else:
                    named = dir_ / str('%s.py' % name)
                    if named.isfile():
                        item = named
        if version and arguments.get('version'):
            item = '%s, %s' % (path, version)
        if item:
            strings.append(str(item))
    return strings;


def script():
    found = False
    modules = set()
    for module in arguments.get('modules'):
        if built_in(module):
            show('builtin', module)
            found = True
            continue
        path, version_ = path_to_import(module, arguments.get('quiet'))
        if path:
            modules.add((module, path, version_))
            found = True
    if not modules:
        return found
    paths_ = module_paths(modules)
    if not paths_:
        return False
    string = ' '.join(sorted([str(p) for p in paths_]))
    show(string)
    return bool(string)
