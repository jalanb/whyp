"""Read files that bash will source

bash's `source` builtin will parse out aliases / functions from source files
    and allow their use as commands in the shell

This module provides a source() method to recognise aliases / functions
    and tag them for later use
"""

try:
    import yaml
except ImportError:
    import sys
    raise ValueError(sys.executable)

from os import path

_file = '.'.join((path.splitext(__file__)[0], 'yaml'))  # static to importers

optional = False  # volatile to importers

_sources = []


def load(option):
    """Provide the data from a yaml file"""
    global optional
    optional = option
    try:
        with open(_file) as stream:
            global _sources
            _sources = yaml.safe_load(stream)
    except FileNotFoundError:
        if optional:
            return []
        import pudb; pudb.set_trace()  # pylint: disable=multiple-statements


def save(item=None):
    if item and item not in _sources:
        _sources.append(item)
    try:
        with open(_file, 'w') as stream:
            yaml.safe_dump(_sources or [], stream)
        return True
    except:
        return optional


def clear():
    global _sources
    _sources = []
    return save() or optional


def source(path_to_file):
    if path.isfile(path_to_file):
        if path_to_file in _sources:
            return True
        return save(path_to_file)
    return optional


def any():
    return bool(_sources) or optional

def all():
    return _sources or ([] if optional else None)

