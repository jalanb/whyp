"""Handle command line arguments for whyp"""

import argparse


def parser(doc):
    """Look for options from user on the command line for this script"""
    global _parser
    _parser = argparse.ArgumentParser(description=doc.splitlines()[0])
    return _parser


def parse_args():
    global _args
    _args = _parser.parse_args()


def get(name):
    """The values of arguments set by user on command line

    This method could be replaced by parse_args() in a program
        or by setUp() in a test

    If not replaced: disregards name, gives empty string
    """
    return getattr(_args, name, None)


def put(name, value):
    """Add an argument the user forgot"""
    setattr(_args, name, value)


_args = argparse.Namespace()
_parser = None
