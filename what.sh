#! /usr/bin/env bash

[[ -n $WELCOME_BYE ]] && echo Welcome to $(basename "$BASH_SOURCE") in $(dirname $(readlink -f "$BASH_SOURCE")) on $(hostname -f)

# This script is intended to be sourced, not run
if [[ "$0" == $BASH_SOURCE ]]; then
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
[[ $SOURCED_FILES =~ $BASH_SOURCE ]] || SOURCED_FILES="${SOURCED_FILES}$BASH_SOURCE"

WHAT_SOURCE=$BASH_SOURCE
export WHAT_DIR=$(dirname $(readlink -f $WHAT_SOURCE))

# x

alias w=what_w

# xx

alias wp=whap
alias ww=what_ww

# xxx

alias www=what_www

# xxxx

whap () {
    local __doc__='find what python will import for a string'
    local executable=python
    if [[ -f "$1" && -x "$1" ]]; then
        executable="$1"
        shift
    elif [[ "$1" =~ [23].[0-9] ]]; then
        executable=python$1
        shift
    fi
    if [[ $* =~ -U ]]; then
        $executable $WHAT_DIR/whap.py "$@"
    else
        $($executable $WHAT_DIR/whap.py "$@")
    fi
}

# Posted as "The most productive function I have written"
# https://www.reddit.com/r/commandline/comments/2kq8oa/the_most_productive_function_i_have_written/

we () {
    local __doc__='Edit the first argument if it is a text file, function or alias'
    if whap -q $1; then
        _sought=$1; shift
        # echo "Found a python module $(whap $_sought)"
        _edit_file $(whap $_sought) "$@"
        return 1
    fi
    # echo "Not a python module"
    if [[ $(type -t $1) == "file" ]]; then
        # echo "is a file"
        _edit_file $1
    elif is_existing_function $1; then
        # echo "is a function"
        _parse_function $1
        _edit_function
    elif is_existing_alias $1; then
        # echo "is alias"
        _edit_alias $1
    else type $1
        vf +/^$1
    fi
    # echo "Bye from we"
}

wf () {
    readlink -f "$@"
}

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

# xxxxx

# xxxxxx

_parse_function () {
    __parse_function_line_number_and_path_to_file $(_debug_declare_function "$1")
}

what_w () {
    local __doc__='Show whether the first argument is a text file, alias or function'
    if is_existing_alias "$1"; then
        alias "$1"
    elif is_existing_function "$1"; then
        _parse_function "$1"
        local _above=$(( $line_number - 1 ))
        echo
        grep "^$function " "$path_to_file" -A4 -n --color
        echo
        echo "vim $(relpath ""$path_to_file"") +$_above +/'\\<$function\\zs.*'"
    elif which "$1" > /dev/null 2>&1; then
        real_file=$(readlink -f $(which "$1"))
        if [[ $real_file != "$1" ]]; then
            echo "$1 -> $real_file"
        fi
        ls -l $(readlink -f $(which "$1"))
    else type "$1"
    fi
}


# xxxxxxx

what_file () {
    what -f -v "$1" # | head -n ${2:-$(( $LINES / 2 ))}
}

what_ww () {
    local __doc__='what(all arguments (whether they like it or not))'
    PASS=0
    FAIL=1
    [[ -z "$@" ]] && return $FAIL
    [[ "$1" == -q ]] && return what "$@"
    if [[ $(type -t "$1") == "file" ]]; then
        what_file "$1"
        return $PASS
    fi
    what -v "$@" && return $PASS
    echo $1 not found
    w ${1:0:${#1}-1} && return $PASS
    return $FAIL
}

# xxxxxxxx

_is_number () {
    local __doc__='Whether the first argument has only digits'
    [[ "$1" =~ ^[0-9]+$ ]]
}

w_source () {
    [[ -z $1 ]] && echo no_path >&2 || [[ ! -f "$1" ]] && echo not_path $1 >&2 || source_what "$@"
}

what_www () {
    . ~/hub/what/what.sh
    (DEBUGGING=www;
    local _command="$1"; shift
    ww $_command;
    w $_command;
    if is_existing_function $_command; then
        (set -x; $_command "$@" 2>&1 ) # | ~/hub/what/spacify)
    elif is_existing_alias $_command; then
        (set -x; $_command "$@" 2>&1 ) # | ~/hub/what/spacify)
    elif file $_command  | grep -q -e script -e text; then
        what_wwm $_command "$@"
    else
        echo 0
    fi)
}

# xxxxxxxxx

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
    type "$1"
}

source_what () {
    local __doc__="Source a file (that may set some aliases) and remember that file"
    local _filename=$(readlink -f "$1")
    if [ -z "$_filename" -o ! -f "$_filename" ]; then
        if [[ -z $2 || $2 != "optional" ]]; then
            echo Cannot source \"$1\". It is not a file. >&2
        fi
        return
    fi
    if [ -z "$SOURCED_FILES" ]; then
        export SOURCED_FILES=$_filename
    else
        if [[ $SOURCED_FILES =~ $_filename ]]; then
            : # return 0
        else
            SOURCED_FILES="$SOURCED_FILES:$_filename"
            export SOURCED_FILES
        fi
    fi
    # echo "${INDENT}source $_filename"
    # local OLDINDENT="$INDENT"
    # local INDENT="$INDENT  "
    source "$_filename"
    # INDENT="$OLDINDENT"
    # echo "${INDENT}have $_filename"
}
alias .=source_what

# Methods starting with underscores are intended for use in this file only
#   (a convention borrowed from Python)

# XXXXXXXXX.

_what_tabify () {
    grep -q "^+"
}
_read_wee_args () {
    local __doc__='evalute the args to the wee function by type, not position'
    for arg in $*
    do
        if _is_script_name $arg; then
            path_to_file="$arg"
        elif _is_number $arg; then
            history_index=$arg
        elif _is_identifier $arg; then
            is_executable $arg && return 1
            function=$arg
        fi
    done
}

_write_new_file () {
    local __doc__='Copy the head of this script to file'
    head -n $_heading_lines $BASH_SOURCE > "$path_to_file"
}

_create_function () {
    local __doc__='Make a new function with a command in shell history'
    local doc="copied from $(basename $SHELL) history on $(date)"
    local history_command=$(_show_history_command)
    eval "$function() { local __doc__='$doc'; $history_command; }" 2>/dev/null
}

_make_path_to_file_exist () {
    local __doc__='make sure the required file exists, either an existing file, a new file, or a temp file'
    if [[ -f "$path_to_file" ]]; then
        cp "$path_to_file" "$path_to_file~"
        return 0
    fi
    if [[ -z "$path_to_file" ]]; then
        path_to_file=$(mktemp /tmp/function.XXXXXX)
    fi
    _write_new_file "$path_to_file"
    [[ $function == $unamed_function ]] || return 1
    line_number=$(wc -l "$path_to_file")
    declare -f $unamed_function >> "$path_to_file"
}

_vim_tabs () {
    echo ${EDITOR:-vim -p}
}

_vim_file () {
    local _file="$1";shift
    $(_vim_tabs) "$_file" "$@"
}

_vim_line () {
    local _file="$1";shift
    local _line="$1";shift
    _vim_file  "$_file" +$line
}

_edit_function () {
    local __doc__='Edit a function in a file'
    _make_path_to_file_exist
    local line_=
    [[ -n "$line_number" ]] && line_="+$line_number"
    local regexp="^$function[[:space:]]*()[[:space:]]*{[[:space:]]*$"
    local regexp_=+/$regexp
    if ! grep -q $regexp "$path_to_file"; then
        declare -f $function >> "$path_to_file"
    fi
    local _line=; [[ -n "$line_number" ]] && _line=+$line_number
    _vim_file "$path_to_file" $line_ $regexp_
    test -f "$path_to_file" || return 0
    ls -l "$path_to_file"
    w_source "$path_to_file"
    [[ $(basename $(dirname "$path_to_file")) == tmp ]] && rm -f "$path_to_file"
}

is_executable () {
    local __doc__='Whether the name is in use as an alias, executable, ...'
    if is_existing_function "$1"; then
        return 1
    else type "$1" 2>/dev/null
    fi
}

_show_history_command () {
    local __doc__='Get a command from the end of current bash history'
    local line=
    local words=$(fc -ln -$history_index -$history_index)
    for word in $words
    do
        if [[ ${word:0:1} != "-" ]]; then
            is_existing_alias $word && word="\\$word"
        fi
        [[ -z $line ]] && line=$word || line="$line $word"
    done
    echo $line
}

_is_script_name () {
    local __doc__='Whether the first argument ends in .sh, or is a file'
    [[ "$1" =~ \.sh$ || -f "$1" ]]
}

_is_identifier () {
    local __doc__='Whether the first argument is alphanumeric and underscores'
    [[ "$1" =~ ^[[:alnum:]_]+$ ]]
}

_debug_declare_function () {
    local __doc__='Find where the first argument was loaded from'
    shopt -s extdebug
    declare -F "$1"
    shopt -u extdebug
}

__parse_function_line_number_and_path_to_file () {
    local __doc__='extract the ordered arguments from a debug declare'
    function="$1";
    shift;
    line_number="$1";
    shift;
    path_to_file="$*";
}

source_path () {
    test -f "$1" && w_source "$@" || return 1
}

_edit_file () {
    local __doc__='Edit a file, it is seems to be text, otherwise tell user why not'
    local file=$(python $WHAT_DIR/what.py -f $1)
    if file $file | grep -q text; then
        _vim_file  $file
    else
        echo $file is not text >&2
        file $file >&2
    fi
}

is_existing_function () {
    local __doc__='Whether the first argument is in use as a function'
    [[ "$(type -t $1)" == "function" ]]
}

is_existing_alias () {
    local __doc__='Whether the first argument is in use as a alias'
    [[ "$(type -t $1)" == "alias" ]]
}

[[ -n $WELCOME_BYE ]] && echo Bye from $(basename "$BASH_SOURCE") in $(dirname $(readlink -f "$BASH_SOURCE")) on $(hostname -f)
