#! /usr/bin/env bash

# This script is intended to be sourced, not run
if [[ $0 == $BASH_SOURCE ]]; then
    echo "This file should be run as"
    echo "  source $0"
    echo "and should not be run as"
    echo "  sh $0"
fi
#
_license="This script is released under the MIT license, see accompanying LICENSE file"
#
_heading_lines=13 # Text before here is copied to new files

WHAT_SOURCED=1
export WHAT_SOURCED
[[ -n $SOURCED_FILES ]] || SOURCED_FILES=$(readlink -f $BASH_SOURCE)

WHAT=$BASH_SOURCE
export WHAT_DIR=$(dirname $(readlink -f $WHAT))

what () {
    local __doc__='find what will be executed for a command string'
    PATH_TO_ALIASES=/tmp/aliases
    PATH_TO_FUNCTIONS=/tmp/functions
    alias > $PATH_TO_ALIASES
    declare -f > $PATH_TO_FUNCTIONS
    python $WHAT_DIR/what.py --aliases=$PATH_TO_ALIASES --functions=$PATH_TO_FUNCTIONS "$@";
    local return_value=$?
    rm -f $PATH_TO_ALIASES
    rm -f $PATH_TO_FUNCTIONS
    return $return_value
}

head_what () {
    return what -v $1 | head -n ${2:-$(( $LINES / 2 ))}
}

w () {
    PASS=0
    FAIL=1
    local __doc__='what(all arguments (whether they like it or not))'
    [[ -z "$@" ]] && return $FAIL
    [[ $1 == -q ]] && return what "$@"
    [[ $(type -t $1) == "file" ]] && return head_what $1
    what -v "$@" && return $PASS
    w ${1:0:${#1}-1} && return $PASS
    echo 'what not "'"$@"'"' >&2
    return $FAIL
}

wa () {
    we "$@"
}

we () {
    local __doc__='Edit the first argument if it is a text file, function or alias'
    if [[ $(type -t $1) == "file" ]]; then
        _edit_file $1
    elif _is_existing_function $1; then
        _de_declare_function $1
        _edit_function
    elif _is_existing_alias $1; then
        _edit_alias $1
    else type $1
    fi
}

wf () {
    local __doc__="if w args then look in the files"
    for arg in "$@"; do
        if [[ $(type -t "$arg") == "file" ]]; then
            grep --color -nH --binary-files=without-match $arg
        fi
    done
}

ww () {
    local __doc__='Show whether the first argument is a text file, alias or function'
    if _is_existing_alias $1; then
        alias $1
    elif _is_existing_function $1; then
        _de_declare_function $1
        echo vim $path_to_file +$line_number +/$1
    elif which $1 > /dev/null 2>&1; then
        real_file=$(readlink -f $(which $1))
        if [[ $real_file != $1 ]]; then
            echo "$1 -> $real_file"
        fi
        ls -l $(readlink -f $(which $1))
    else type $1
    fi
}

whap () {
    local __doc__='find what python will import for a string'
    local executable=python
    if [[ -f $1 && -x $1 ]]; then
        executable=$1
        shift
    elif [[ $1 =~ [23].[0-9] ]]; then
        executable=python$1
        shift
    fi
    if [[ $* =~ -U ]]; then
        $executable $WHAT_DIR/whap.py "$@"
    else
        $($executable $WHAT_DIR/whap.py "$@")
    fi
}

whet () {
    local __doc__='whet makes it easier to name a command, then re-edit it'
    local unamed_function=fred
    local function=
    local history_index=1
    local path_to_file=
    local line_number=
    _read_whet_args $* || return $?
    if [[ -z $function ]]; then
        unset $unamed_function
        function=$unamed_function
    fi
    if _is_existing_function $function; then
        _de_declare_function $function
        _edit_function
    else
        _create_function
        _edit_function
    fi
}

source_what () {
    local __doc__="Source a file (which might set some aliases) and remember that file"
    local _filename="$1"
    if [ -z "$_filename" -o ! -f "$_filename" ]; then
        if [[ -z $2 || $2 != "optional" ]]; then
            echo Cannot source \"$_filename\". It is not a file. >&2
        fi
        return
    fi
    # echo SOURCED_FILES= $SOURCED_FILES
    if [ -z "$SOURCED_FILES" ]; then
        export SOURCED_FILES=$_filename
    else
        if ! echo $SOURCED_FILES | tr ':' ' ' | grep -x -c -q $_filename; then
            SOURCED_FILES="$SOURCED_FILES:$_filename"
        fi
    fi
    export SOURCED_FILES
    source "$@"
}
alias .=source_what

# Methods starting with underscores are intended for use in this file only
#   (a convention borrowed from Python)

w_source () {
    [[ -z $1 ]] && echo no_path >&2 || [[ ! -f $1 ]] && echo not_path $1 >&2 || source_what "$@"
}

source_path () {
    test -f $1 && w_source "$@" || return 1
}

_read_whet_args () {
    local __doc__='evalute the args to the whet function by type, not position'
    for arg in $*
    do
        if _is_script_name $arg; then
            path_to_file=$arg
        elif _is_number $arg; then
            history_index=$arg
        elif _is_identifier $arg; then
            _existing_command $arg && return 1
            function=$arg
        fi
    done
}

_create_function () {
    local __doc__='Make a new function with a command in shell history'
    local doc="copied from $(basename $SHELL) history on $(date)"
    local history_command=$(_show_history_command)
    eval "$function() { local __doc__='$doc'; $history_command; }" 2>/dev/null
}

_write_new_file () {
    local __doc__='Copy the head of this script to file'
    head -n $_heading_lines $BASH_SOURCE > $path_to_file
}

_make_path_to_file_exist () {
    local __doc__='make sure the required file exists, either an existing file, a new file, or a temp file'
    if [[ -n $path_to_file ]]; then
        if [[ -f $path_to_file ]]; then
            cp $path_to_file $path_to_file~
        else
            _write_new_file $path_to_file
            if [[ $function == $unamed_function ]]; then
                line_number=$(wc -l $path_to_file)
                declare -f $unamed_function >> $path_to_file
            fi
        fi
    else
        path_to_file=$(mktemp /tmp/function.XXXXXX)
    fi
}

_edit_function () {
    local __doc__='Edit a function in a file'
    _make_path_to_file_exist
    if [[ -n "$line_number" ]]; then
        ${EDITOR:-vim} $path_to_file +$line_number
    else
        local regexp="^$function[[:space:]]*()[[:space:]]*$"
        if ! grep -q $regexp $path_to_file; then
            declare -f $function >> $path_to_file
        fi
        ${EDITOR:-vim} $path_to_file +/$regexp
    fi
    ls -l $path_to_file
    w_source $path_to_file
    [[ $(dirname $path_to_file) == /tmp ]] && rm -f $path_to_file
}

_is_existing_function () {
    local __doc__='Whether the first argument is in use as a function'
    [[ "$(type -t $1)" == "function" ]]
}

_edit_alias () {
    local __doc__='Edit an alias in the file $ALIASES, if that file exists'
    test -n "$SOURCED_FILES" || return
    OLD_IFS=$IFS
    IFS=:; for sourced_file in $SOURCED_FILES
    do
        line_number=$(grep -nF "alias $1=" $sourced_file | cut -d ':' -f1)
        if [[ -n "$line_number" ]]; then
            ${EDITOR:-vim} $sourced_file +$line_number
        fi
    done
    IFS=$OLD_IFS
    type $1
}

_is_existing_alias () {
    local __doc__='Whether the first argument is in use as a alias'
    [[ "$(type -t $1)" == "alias" ]]
}

_existing_command () {
    local __doc__='Whether the name is in use as an alias, executable, ...'
    if _is_existing_function $1; then
        return 1
    else type $1 2>/dev/null
    fi
}

_show_history_command () {
    local __doc__='Get a command from the end of current bash history'
    local line=
    local words=$(fc -ln -$history_index -$history_index)
    for word in $words
    do
        if [[ ${word:0:1} != "-" ]]; then
            _is_existing_alias $word && word="\\$word"
        fi
        [[ -z $line ]] && line=$word || line="$line $word"
    done
    echo $line
}

_is_script_name () {
    local __doc__='Whether the first argument ends in .sh, or is a file'
    [[ "$1" =~ \.sh$ || -f $1 ]]
}

_is_number () {
    local __doc__='Whether the first argument has only digits'
    [[ "$1" =~ ^[0-9]+$ ]]
}

_is_identifier () {
    local __doc__='Whether the first argument is alphanumeric and underscores'
    [[ "$1" =~ ^[[:alnum:]_]+$ ]]
}

_debug_declare_function () {
    local __doc__='Find where the first argument was loaded from'
    shopt -s extdebug
    declare -F $1
    shopt -u extdebug
}

_parse_declaration () {
    local __doc__='extract the ordered arguments from a debug declare'
    function=$1;
    shift;
    line_number=$1;
    shift;
    path_to_file="$*";
}

_de_declare_function () {
    local __doc__='Set symbols for the file and line of a function'
    _parse_declaration $(_debug_declare_function $1)
}

_edit_file () {
    local __doc__='Edit a file, it is seems to be text, otherwise tell user why not'
    local file=$(python $WHAT_DIR/what.py -f $1)
    if file $file | grep -q text; then
        ${EDITOR:-vim} $file
    else
        echo $file is not text >&2
        file $file >&2
    fi
}

# echo "from what/what.sh"
