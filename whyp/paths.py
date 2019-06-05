"""A more functional approach to paths"""
from os import path as op
from functools import partial


def add_method(instance, name, method):
    instance.__dict__[name] = partial(method, str(instance))


def as_string(string=None):
    return string and string or ''


def as_path(s):
    return WhypPath(s)


def directory(s):
    string = str(s)
    if not string or op.isdir(string):
        return string
    if op.exists(string):
        return op.dirname(string)
    return string

class WhypPath(object):
    def __init__(self, string):
        self.string = str(string)
        self.__dict__.update(dict(
            dir=lambda: as_path(directory(self)),
            directory=lambda : as_path(directory(self)),
            real=lambda: as_path(op.exists(str(self)) and op.realpath(str(self)) or ''),
            base=lambda: as_path(op.basename(self.string)),
            sibling=lambda x: directory(self) == directory(x),
            join=lambda x: as_path(op.join(str(self), str(x))),
            isfile=lambda : bool(op.isfile(self.string)),
            isdir=lambda : bool(op.isdir(self.string)),
            exists=lambda : bool(op.exists(self.string)),
        ))

    def __str__(self):
        return self.string or ''

    def __repr__(self):
        return f'<{self.__class__.__name__} {self.string}>'

    def __eq__(self, other):
        return str(other) == str(self)

    def __len__(self):
        return len(self.string)

    def __truediv__(self, other):
        return self.join(other)

    def dirname(s):
        string = str(s)
        if op.isdir(string):
            result = string
        elif op.exists(string):
            result = op.dirname(string)
        else:
            result = as_string()
        return as_path(op.basename(result))



def _predicated_path(predicate):
    return lambda x: WhypPath(str(x) if predicate(x) else as_string())


abs_ = _predicated_path(op.isabs)
isdir = _predicated_path(op.isdir)
exists = _predicated_path(op.exists)
isfile = _predicated_path(op.isfile)
link = _predicated_path(op.islink)
mount = _predicated_path(op.ismount)
