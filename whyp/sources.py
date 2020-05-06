"""Read files that bash will source

bash's `source` builtin will parse out aliases / functions from source files
    and allow their use as commands in the shell

This module provides a source() method to recognise aliases / functions
    and tag them for later use
"""

import yaml
import os
from os import path as op

from pysyte.types import paths

_file = '.'.join((op.splitext(__file__)[0], 'yaml'))  # static to importers

optional = False  # volatile to importers

def load(optional):
    """Provide the data from a yaml file"""
    if not op.isfile(_file):
        return set()
    try:
        with open(_file) as stream:
            return set(yaml.safe_load(stream) or [])
    except FileNotFoundError:
        if optional:
            return set()
        raise


_sources = load(True)


def save():
    real_sources = sorted([s for s in _sources if op.isfile(s)])
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
    if op.isfile(path_to_file):
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
