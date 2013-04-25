#! /bin/bash

# This script is intended to be sourced, not run
if [[ $0 == $BASH_SOURCE ]]
then
    echo "This file should be run as"
    echo "  source $0"
    echo "and should not be run as"
    echo "  sh $0"
fi

what ()
{
	PATH_TO_ALIASES=/tmp/aliases
	PATH_TO_FUNCTIONS=/tmp/functions
    alias > $PATH_TO_ALIASES
    declare -f > $PATH_TO_FUNCTIONS
    python $JAB/python/what/what.py --aliases=$PATH_TO_ALIASES --functions=$PATH_TO_FUNCTIONS $*;
	rm -f $PATH_TO_ALIASES
	rm -f $PATH_TO_FUNCTIONS
}

whap ()
{
	python $JAB/python/what/whap.py $*
}
