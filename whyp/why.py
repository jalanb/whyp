"""Show the text behind the type"""

import os
import re
import sys
import stat
import doctest
import subprocess
from collections import defaultdict
from bdb import BdbQuit

from pysyte.iteration import first
from pysyte.types import paths

from whyp import arguments
from whyp import shell


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
    path_to_vimcat = shell.which('vimcat')
    if os.path.isfile(path_to_vimcat):
        return path_to_vimcat
    parent = os.path.dirname
    path_to_hub = parent(parent(__file__))
    vimcat_dirs = ['vimcat', 'vimpager', 'vim-scripts']
    for vimcat_dir in vimcat_dirs:
        path_to_vimcat = os.path.join(path_to_hub, vimcat_dir, 'vimcat')
        if os.path.isfile(path_to_vimcat):
            return path_to_vimcat
    return shell.which('less')


def replace_alias(command):
    """Replace any alias with its value at start of the command"""
    if ' ' not in command:
        return command
    command, args = command.split(' ', 1)
    return '%s %s' % (find_alias(command), args)


def bash_executable():
    """The first executable called 'bash' in the $PATH"""
    return shell.which('bash')


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
        if arguments.get('hide_errors'):
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
    first_ = string[0]
    last = string[-1]
    if first_ == last and first_ in '"\'':
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


def read_command_line():
    arguments.put('aliases', '/tmp/aliases')
    arguments.put('functions', '/tmp/functions')


@memoize
def get_aliases():
    """Read a dictionary of aliases from a file"""
    aliases = arguments.get('aliases')
    try:
        stream = open(aliases) if aliases else []
        lines = [l.rstrip() for l in stream]
    except IOError:
        return {}
    alias_lines = [l[6:] for l in lines if l.startswith('alias ')]
    alias_strings = [l.split('=', 1) for l in alias_lines]
    alias_commands = [(n, strip_quotes(c)) for (n, c) in alias_strings]
    return dict(alias_commands)


def find_alias(string):
    """Give the alias for that string, or the string itself"""
    return get_aliases().get(string, string)


def is_alias(string):
    return bool(get_alias(string))


def get_alias(string):
    return get_aliases().get(string, None)


@memoize
def get_functions():
    """Read a dictionary of functions from a known file"""
    arg_funcs = arguments.get('functions')
    try:
        stream = open(arg_funcs) if arg_funcs else []
        lines = [l.rstrip() for l in stream]
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


def is_function(name):
    function = get_functions().get(name, None)
    return bool(function)


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
    if not arguments.get('verbose'):
        print('%s is a function' % command)
    else:
        commands = ' | '.join([
            "shopt -s extglob; . %s; %s %s" % (
                arguments.get('functions'), Bash.declare_f, command),
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
    path_to_command = shell.which(command)
    show_command_file(path_to_command)


def show_command_file(path_to_command):
    """Show a command which is a file at that path"""
    if arguments.get('ls'):
        show_output_of_shell_command('%s -l %r' % (Bash.ls, path_to_command))
    else:
        p = os.path.realpath(path_to_command)
        if os.path.exists(p):
            print(p)
    if not arguments.get('verbose'):
        return
    language = script_language(path_to_command)
    if showable(language):
        show_output_of_shell_command('%s %r' % (
            Bash.view_file, str(path_to_command)))


def show_alias(command):
    """Show a command defined by alias"""
    alias = get_alias(command)
    print('alias %s=%r' % (command, alias))
    if not arguments.get('verbose'):
        return
    sub_command = alias.split()[0].strip()
    if sub_command == command:
        return
    if os.path.dirname(sub_command) in shell.paths():
        show_command(os.path.basename(sub_command))
    else:
        show_command(sub_command)


def nearby_file(named_file, extension):
    """Return the name of that file, changed to use that extension

    >>> os.path.basename(nearby_file('whyp.pyc', '.txt')) == 'whyp.txt'
    True
    """
    return os.path.splitext(named_file)[0] + extension


def show_command(command):
    """Show whatever is behind a command"""
    methods = []
    if arguments.get('file'):
        methods = [
            (os.path.isfile, show_command_file),
        ]
    elif not arguments.get('quiet'):
        methods = [
            (is_alias, show_alias),
            (is_function, show_function),
            (shell.is_path_command, show_command_in_path),
            (os.path.isfile, show_command_file),
        ]
    try:
        for is_command, show_command in methods:
            if is_command(command):
                show_command(command)
                return True
    except ValueError as e:
        pass
    return False
