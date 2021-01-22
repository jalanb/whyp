"""Read files that bash will source

bash's `source` builtin will parse out aliases / functions from source files
    and allow their use as commands in the shell

This module provides a source() method to recognise aliases / functions
    and tag them for later use
"""

import os
from os import path as op
from typing import List

import yaml
from pysyte.types import paths

def _path_to_yaml():
    return paths.path(__file__).extend_by('yaml')


optional = False  # volatile to importers

def load(path: paths.FilePath) -> List[str]:
    """Provide the data from a yaml file"""
    try:
        with open(path) as stream:
            loaded = set(yaml.safe_load(stream) or [])
            return sorted(loaded)
    except FileNotFoundError:
        if not optional:
            raise
    return []


def load_files(path: paths.FilePath) -> List[paths.FilePath]:
    """Provide the files from a yaml file"""
    if not path.isfile():
        return []
    return [_ for _ in load(path)]


_sources = load_files(_path_to_yaml())


def save():
    real_sources = sorted([s for s in _sources if op.isfile(s)])
    try:
        with open(_path_to_yaml(), 'w') as stream:
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
