#! /usr/bin/env python3
"""Show the text behind the type

This script is intended to replace the standard type command
It should look for commands in aliases, bash functions, and the bash $PATH
It assumes aliases and functions have been written to files before starting
    (because this script cannot reliably get them from sub-shells)
"""



import sys
import argparse

from whyp import why
from whyp import arguments

def parse_args():
    """Look for options from user on the command line for this script"""
    parser = arguments.parser(__doc__)
    pa = parser.add_argument
    pa('commands', nargs='+', help='the commands to be typed')
    pa('-e', '--hide_errors', action='store_true',
                      help='hide error messages from successful commands')
    pa('-l', '--ls', action='store_true',
                      help='show output of "ls path" if it is a path')
    pa('-f', '--file', action='store_true',
                      help='do not show any output')
    pa('-q', '--quiet', action='store_true',
                      help='do not show any output')
    pa('-v', '--verbose', action='store_true',
                      help='whether to show more info, such as file contents')
    pa('-A', '--aliases', default='/tmp/aliases',
                      help='path to file which holds aliases')
    pa('-F', '--functions', default='/tmp/functions',
                      help='path to file which holds functions')
    return arguments.parse_args()


def main():
    """Run the program"""
    parse_args()
    result = 0
    for command in arguments.get('commands'):
        result |= why.show_command(command)
    return result


if __name__ == '__main__':
    sys.exit(0 if main() else 1)
