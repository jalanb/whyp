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
    alias > /tmp/aliases;
    declare -f > /tmp/functions;
    python $JAB/python/what/what.py $*;
    rm -f /tmp/aliases /tmp/functions
}

