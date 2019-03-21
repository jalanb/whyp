"""Read files that bash will source

bash's `source` builtin will parse out aliases / functions from source files
    and allow their use as commands in the shell

This module provides a source() method to recognise aliases / functions
    and tag them for later use
"""

import yaml
from os import path

_file = '.'.join((path.splitext(__file__)[0], 'yaml'))  # static to importers

optional = False  # volatile to importers

def load(optional):
    """Provide the data from a yaml file"""
    if not path.isfile(_file):
        return optional and [] or False
    try:
        with open(_file) as stream:
            return set(yaml.safe_load(stream) or [])
    except FileNotFoundError:
        if optional:
            return set()
        raise


_sources = load(True)


def save():
    real_sources = sorted([s for s in _sources if path.isfile(s)])
    try:
        with open(_file, 'w') as stream:
            yaml.safe_dump(real_sources, stream)
        return True
    except:
        return optional


def clear():
    global _sources
    _sources = set()
    return save() or optional


def source(path_to_file):
    if path.isfile(path_to_file):
        if path_to_file in _sources:
            return True
        _sources.add(path_to_file)
        save()
        return True
    return optional


def any():
    return bool(_sources) or optional

def all():
    return _sources or ([] if optional else None)

