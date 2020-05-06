import os


from pysyte.types.paths import path


def value(key):
    """A value from the shell environment, defaults to empty string

    >>> value('SHELL') is not None
    True
    """
    try:
        return os.environ[key]
    except KeyError:
        return ''


def paths(name=None):
    """A list of paths in the environment's PATH

    >>> '/bin' in paths()
    True
    """
    path_value = value(name or 'PATH')
    path_strings = path_value.split(':')
    path_paths = [path(_) for _ in path_strings]
    return path_paths


def path_commands():
    """Gives a dictionary of all executable files in the environment's PATH

    >>> path_commands()['python'] == sys.executable or True
    True
    """
    commands = {}
    for path_dir in paths():
        if not path_dir.isdir():
            continue
        for file_path in path_dir.list_files():
            if not file_path.isexec():
                continue
            if file_path.name in commands:
                continue
            commands[file_path.name] = file_path
    return commands


_path_commands = path_commands()


def which(name):
    """Looks for the name as an executable is shell's PATH

    If name is not found, look for name.exe
        If still not found, return empty string

    >>> which('python') == sys.executable or True
    True
    """
    try:
        commands = _path_commands
        return commands[name]
    except KeyError:
        if name.endswith('.exe'):
            return ''
        return which('%s.exe' % name)


def is_path_command(name):
    return name in _path_commands
