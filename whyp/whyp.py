"""Show the text behind the type

This script is intended to replace the standard type command
It should look for commands in aliases, bash functions, and the bash $PATH
It assumes aliases and functions have been written to files before starting
    (because this script cannot reliably get them from sub-shells)
"""


import os
import re
import sys
import stat
import doctest
import optparse
import subprocess
from collections import defaultdict
from bdb import BdbQuit


_copyright = """
(c) J Alan Brogan 2013
    The source is released under the MIT license
    See http://jalanb.mit-license.org/ for more information
"""

from whyp import arguments

version = '0.7.0'


def environment_value(key):
    """A value from the shell environment, defaults to empty string

    >>> environment_value('SHELL') is not None
    True
    """
    return os.environ.get(key, '')


class BashError(ValueError):
    """Use this class to have better name appear in tracebacks"""
    pass


def pager():
    """Try to use vimcat as a pager, otherwise less

    vimcat is a provided by https://github.com/vim-scripts/vimcat
        This file is also provide by a github repo
        Hence assumption: vimcat is at ../../vim-scripts/vimcat
    vimcat originated at https://github.com/rkitover/vimpager
        So try ../../vimpager/vimcat too
    """
    path_to_vimcat = file_in_environment_path('vimcat')
    if os.path.isfile(path_to_vimcat):
        return path_to_vimcat
    parent = os.path.dirname
    path_to_hub = parent(parent(__file__))
    vimcat_dirs = ['vimcat', 'vimpager', 'vim-scripts']
    for vimcat_dir in vimcat_dirs:
        path_to_vimcat = os.path.join(path_to_hub, vimcat_dir, 'vimcat')
        if os.path.isfile(path_to_vimcat):
            return path_to_vimcat
    return file_in_environment_path('less')


def replace_alias(command):
    """Replace any alias with its value at start of the command"""
    if ' ' not in command:
        return command
    command, arguments = command.split(' ', 1)
    return '%s %s' % (get_alias(command), arguments)


def bash_executable():
    """The first executable called 'bash' in the $PATH"""
    return file_in_environment_path('bash')


def show_output_of_shell_command(command):
    """Run the given command using bash"""

    def as_str(bytes_):
        return bytes_.decode(sys.stdin.encoding)

    command = replace_alias(command)
    bash_command = [bash_executable(), '-c', command]
    process = subprocess.Popen(
        bash_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    if not process.returncode:
        # Use sys.stdout.buffer because the output probably includes
        # ANSI colour sequences (making it bytes, not string)
        # https://stackoverflow.com/a/4374457/500942
        try:
            sys.stdout.buffer.write(stdout)
        except AttributeError:
            print(stdout)
        if get_argument('hide_errors'):
            return
        if not stderr:
            return
    raise BashError('''
        command: %r
        status: %s
        stderr: %s
        stdout: %s''' % (
            command, process.returncode, as_str(stderr), as_str(stdout)))


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

    def call_method(*args, **kwargs):
        result = method(*args, **kwargs)
        name = method.__name__
        item = method, result
        cache[name].append(item)
        return result

    cache = defaultdict(list)
    call_method.__doc__ = method.__doc__
    call_method.__name__ = 'memoized_%s' % method.__name__
    return call_method


@memoize
def get_aliases():
    """Read a dictionary of aliases from a file"""
    path = getattr(get_argument(''), 'aliases', None)
    if not path:
        return {}
    try:
        lines = [l.rstrip() for l in open(path)]
    except IOError:
        return {}
    alias_lines = [l[6:] for l in lines if l.startswith('alias ')]
    alias_strings = [l.split('=', 1) for l in alias_lines]
    alias_commands = [(n, strip_quotes(c)) for (n, c) in alias_strings]
    return dict(alias_commands)


def get_alias(string):
    """Give the alias for that string, or the string itself"""
    return get_aliases().get(string, string)


@memoize
def get_functions():
    """Read a dictionary of functions from a known file"""
    try:
        lines = [l.rstrip() for l in open(get_argument('functions'))]
    except IOError:
        return {}
    name = function_lines = None
    functions = {}
    for line in lines:
        if line == '{':
            continue
        elif line == '}':
            if function_lines:
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
    for name, lines in functions.items():
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

    >>> ('local', '/usr/local') in items_in('/usr')
    True
    """
    try:
        return [(name, os.path.join(path, name)) for name in os.listdir(path)]
    except OSError:
        return []


def files_in(path):
    """A list of all files in the given path

    >>> ('bash', '/bin/bash') in files_in('/bin')
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
    """Gives a dictionary of all executable files in the environment's PATH

    >>> files_in_environment_path()['python'] == sys.executable or True
    True
    """
    known_filenames = set()
    result = {}
    for path in environment_paths():
        for filename, path_to_file in executables_in(path):
            if filename in known_filenames:
                continue
            known_filenames.add(filename)
            result[filename] = path_to_file
    return dict(result)


def file_in_environment_path(string):
    """Gives the path to string, or string.exe

    >>> file_in_environment_path('python') == sys.executable or True
    True
    """
    try:
        files = files_in_environment_path()
        return files[string]
    except KeyError:
        if string.endswith('.exe'):
            return ''
        return file_in_environment_path('%s.exe' % string)


class Bash(object):
    """This class is a namespace to hold bash commands to be used later"""
    # pylint wants an __init__(), but I don't
    # pylint: disable=no-init
    view_file = pager()
    declare_f = 'declare -f'  # This is a bash builtin
    ls = 'ls'  # This is often in path, and more often aliased


def showable(language):
    """A list of languages whose source files we are interested in viewing"""
    return language in ['python', 'python2', 'python3', 'bash', 'sh']


def show_function(command):
    """Show a function to the user"""
    if not get_argument('verbose'):
        print('%s is a function' % command)
    else:
        commands = ' | '.join([
            "shopt -s extglob; . %s; %s %s" % (
                get_argument('functions'), Bash.declare_f, command),
            "sed '1 i\\\n#! /usr/bin/env bash\n'",
            Bash.view_file
        ])
        show_output_of_shell_command(commands)


def shebang_command(path_to_file):
    """Get the shebang line of that file

    Which is the first line, if that line starts with #!
    """
    try:
        first_line = open(path_to_file).readlines()[0]
        if first_line.startswith('#!'):
            return first_line[2:].strip()
    except (IndexError, IOError, UnicodeDecodeError):
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
        last_word = command_words[-1]
    except IndexError:
        last_word = None
    return last_word


def script_language(path_to_file):
    """Guess the language used to run a file from its first line

    The language should be the last word on the shebang line (if present)
    If no shebang line is found, try an extension

    >>> script_language('whyp.py') == 'python'
    True
    >>> script_language('script.sh') == 'bash'
    True
    """
    for get_language in [shebang_language, extension_language]:
        language = get_language(path_to_file)
        if language:
            return language


def show_command_in_path(command):
    """Show a command which is a file in $PATH"""
    path_to_command = file_in_environment_path(command)
    show_path_to_command(path_to_command)


def show_path_to_command(path_to_command):
    """Show a command which is a file at that path"""
    if get_argument('ls'):
        show_output_of_shell_command('%s -l %r' % (Bash.ls, path_to_command))
    else:
        p = os.path.realpath(path_to_command)
        if os.path.exists(p):
            print(p)
    if not get_argument('verbose'):
        return
    language = script_language(path_to_command)
    if showable(language):
        show_output_of_shell_command('%s %r' % (
            Bash.view_file, str(path_to_command)))


def show_alias(command):
    """Show a command defined by alias"""
    aliases = get_aliases()
    print('alias %s=%r' % (command, aliases[command]))
    if not get_argument('verbose'):
        return
    sub_command = aliases[command].split()[0].strip()
    if sub_command == command:
        return
    if os.path.dirname(sub_command) in environment_paths():
        show_command(os.path.basename(sub_command))
    else:
        show_command(sub_command)


def show_command(command):
    """Show whatever is behind a command"""
    i = 0
    methods = [
        (lambda x: x in get_aliases(), show_alias),
        (lambda x: x in get_functions(), show_function),
        (lambda x: x in files_in_environment_path(), show_command_in_path),
        (os.path.isfile, show_path_to_command),
    ]
    function = get_functions().get(command, None)
    for found, show in methods:
        if found(command):
            if get_argument('file'):
                if os.path.isfile:
                    show_path_to_command(command)
                else:
                    # show(command) :thinking_face:
                    pass
            elif not get_argument('quiet'):
                show(command)
            return 0
    return 1


def nearby_file(named_file, extension):
    """Return the name of that file, changed to use that extension

    >>> os.path.basename(nearby_file('whyp.pyc', '.txt')) == 'whyp.txt'
    True
    """
    return os.path.splitext(named_file)[0] + extension


def test():
    """Run any doctests in this script or associated test scripts"""
    options = doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE
    all_failures, all_tests = 0, 0
    main_module = sys.modules['__main__']
    failures, tests = doctest.testmod(
        main_module,
        optionflags=options,
    )
    all_failures += failures
    all_tests += tests
    for extension in ['.test', '.tests']:
        main_test = nearby_file(main_module.__file__, extension)
        if not os.path.isfile(main_test):
            continue
        failures, tests = doctest.testfile(
            main_test,
            optionflags=options,
            module_relative=False,
        )
        all_failures += failures
        all_tests += tests
    print('Ran %s tests, %s failures' % (all_tests, all_failures))
    return 0
