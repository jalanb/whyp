#! /usr/bin/env bash

# This script is intended to be sourced, not run
# Read CONTRIBUTIONS.MD before contributing

if [[ "$0" == $BASH_SOURCE ]]; then
    echo "This file should be run as"
    echo "  source $0"
    echo "and should not be run as"
    echo "  sh $0"
fi
#

red () {
    colourise 31 "$@"
}

green () {
    colourise 32 "$@"
}

brown () {
    colourise 33 "$@"
}

blue () {
    colourise 34 "$@"
}

magenta () {
    colourise 35 "$@"
}

cyan () {
    colourise 36 "$@"
}

gray () {
    colourise 37 "$@"
}

grey () {
    colourise 38 "$@"
}

colourised () {
    [[ "$@" ]] || return
    (set -e; set -x;
        touch .colours.out .colours.err
        "$@" > .colours.out 2> .colours.err
        blue -n "$@"
        green -n -f .colours.out
        red -n -f .colours.err
    )
    rm -f .colours.out .colours.err 2> /dev/null
}

colourise () {
    local _light=1
    [[ $1 == "0" ]] && _light=0 && shift
    local _colour="\033[${_light};$1m"; shift
    local _end=
    local _text=
    if [[ $1 == "-[fn]*" ]]
        [[ $1 =~ "-[f]*[n][f]*" ]] && _end="\n"
        [[ $1 =~ "-[n]*[f][n]*" ]] && shift
        local _path=
        _path="$1"
        local _cat=
        [[ -f "$_path" ]] && _cat=cat
        [[ $_cat ]] && _text="$(${_cat} ${_path} ) ${_end}"
    else
        [[ $1 == "-n"]] && _end="\n" && shift
        _text="$@${_end}"
    fi
    local _no_colour="\033[0m"
    printf "${_colour}${_text}${_no_colour}"
}
