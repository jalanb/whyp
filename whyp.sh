#! /usr/bin/env bash

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

[[ -n $WELCOME_BYE ]] && echo Welcome to $(basename "$BASH_SOURCE") in $(dirname $(readlink -f "$BASH_SOURCE")) on $(hostname -f)

WHYP_SOURCED=1
export WHYP_SOURCED
[[ $SOURCES =~ $BASH_SOURCE ]] || SOURCES="${SOURCES}:$BASH_SOURCE"

WHYP_SOURCE=$BASH_SOURCE
export WHYP_DIR=$(dirname $(readlink -f $WHYP_SOURCE))

# x
# xx
# xxx
# xxxx
alias whap=whyp-python


# xxxxx*

whyp-py () {
    python $WHYP_DIR/whyp/whyp.py "$@"
}

whyp-py-file () {
    python $WHYP_DIR/whyp/whyp.py -f "$@"
}


# Posted as "The most productive function I have written"
# https://www.reddit.com/r/commandline/comments/2kq8oa/the_most_productive_function_i_have_written/

eype () {
    local __doc__="""Edit the first argument as if it's a type"""
    if whyp-python -q $1; then
        _sought=$1; shift
        # echo "Found a python module $(whyp-python $_sought)"
        _edit_file $(whyp-python $_sought) "$@"
        return 1
    fi
    # echo "Not a python module"
    if [[ $(type -t $1) == "file" ]]; then
        # echo "is a file"
        _edit_file $1
    elif is-existing-function $1; then
        # echo "is a function"
        _parse_function $1
        _edit_function
    elif is-existing-alias $1; then
        # echo "is alias"
        _edit_alias $1
    else type $1
        vf +/^$1
    fi
}

whyp-command () {
    local __doc__="""find whyp will be executed for a command string"""
    PATH_TO_ALIASES=/tmp/aliases
    PATH_TO_FUNCTIONS=/tmp/functions
    alias > $PATH_TO_ALIASES
    declare -f > $PATH_TO_FUNCTIONS
    whyp-py --aliases=$PATH_TO_ALIASES --functions=$PATH_TO_FUNCTIONS "$@";
    local return_value=$?
    # rm -f $PATH_TO_ALIASES
    # rm -f $PATH_TO_FUNCTIONS
    return $return_value
}

whyp-python () {
    local __doc__="""find what python will import for a string, outside virtualenvs"""
    (deactivate 2>/dev/null
        local _which_py=python
        if [[ "$1" =~ ^[1-9]$ || $1 =~ ^[1-9].[0-9.]+$ ]]; then
            _which_py=python$1
            shift
        fi
        local _exec_py=$(PATH=/usr/local/bin:/usr/bin/:/bin which $_which_py)
        if [[ $1 =~ python && -f "$1" && -x "$1" ]]; then
            _exec_py="$1"
            shift
        fi
        _python=$(rlf $_exec_py)
        if [[ $* =~ -U ]]; then
            $_python $WHYP_DIR/whyp-python.py "$@"
        else
            $($_python $WHYP_DIR/whyp-python.py "$@")
        fi
    )
}

whyp () {
    local __doc__="""whyp will extend type, later"""
    type "$@"
}

show-command () {
    local _arg=$1; shift
    if [[ $_arg =~ -[vq] ]]; then
        shift
        if [[ $_arg =~ -[q] ]]; then
            whyp-command "$@" >/dev/null 2>&1
            return $?
        fi
    fi
    whyp-command "$@"
}

whyp-whyp () {
    local __doc__="""whyp(all arguments (whether they like it or not))"""
    local _pass=0
    local _fail=1
    [[ -z "$@" ]] && return $_fail
    local _options=-v
    if [[ "$1" == -q ]]; then
        _options=-q
        shift
    fi
    if [[ $(type -t "$1") == "file" ]]; then
        show-command $_options "$1"
        return $?
    fi

    show-command $_options "$@" && return $_pass
    [[ $_options == "-v" ]] && echo "$@ not whypped" >&2
    w ${1:0:${#1}-1} && return $_pass
    return $_fail
}

whyp-debug () {
    (DEBUGGING=www;
        local _command="$1"; shift
        ww $_command;
        w $_command;
        (set -x; $_command "$@" 2>&1 )
    )
}

_edit_alias () {
    local __doc__="""Edit an alias in the file $ALIASES, if that file exists"""
    test -n "$SOURCES" || return
    OLD_IFS=$IFS
    IFS=:; for sourced_file in $SOURCES
    do
        line_number=$(grep -nF "alias $1=" $sourced_file | cut -d ':' -f1)
        if [[ -n "$line_number" ]]; then
            ${EDITOR:-vim} $sourced_file +$line_number
        fi
    done
    IFS=$OLD_IFS
    type "$1"
}

_edit_function () {
    local __doc__="""Edit a function in a file"""
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
    whyp-source "$path_to_file"
    [[ $(basename $(dirname "$path_to_file")) == tmp ]] && rm -f "$path_to_file" || true
}

_edit_file () {
    local __doc__="""Edit a file, it is seems to be text, otherwise tell user why not"""
    local file=$(whyp-py -f $1)
    if file $file | grep -q text; then
        _vim_file  $file
    else
        echo $file is not text >&2
        file $file >&2
    fi
}

whyp-source () {
    local __doc__="""Source optionally"""
    source-whyp "$@" optional
}

unalias . 2>/dev/null

source-whyp () {
    local __doc__="""Source a file (that may set some aliases) and remember that file"""
    local _filename=$(readlink -f "$1")
    if [ -z "$_filename" -o ! -f "$_filename" ]; then
        if [[ -z $2 || $2 != "optional" ]]; then
            echo Cannot source \"$1\". It is not a file. >&2
        fi
        return
    fi
    if [ -z "$SOURCES" ]; then
        export SOURCES=$_filename
    else
        if [[ $SOURCES =~ $_filename ]]; then
            : # return 0
        else
            SOURCES="$SOURCES:$_filename"
            export SOURCES
        fi
    fi
    source "$_filename"
}

alias .=source-whyp


# _xxxxx+

_parse_function () {
    __parse_function_line_number_and_path_to_file $(_debug_declare_function "$1")
}

old_whyp-type () {
    if is-existing-alias "$1"; then
        type "$1"
    elif is-existing-function "$1"; then
        type "$1"
        echo
        local _above=$(( $line_number - 1 ))
        echo "vim $(relpath ""$path_to_file"") +$_above +/'\\<$function\\zs.*'"
    elif which "$1" > /dev/null 2>&1; then
        real_file=$(readlink -f $(which "$1"))
        [[ $real_file != "$1" ]] && echo -n "$1 -> "
        echo "$real_file"
    else type "$1"
    fi
}


_is_number () {
    local __doc__="""Whether the first argument has only digits"""
    [[ "$1" =~ ^[0-9]+$ ]]
}

# Methods starting with underscores are intended for use in this file only
#   (another convention borrowed from Python)


_read_wee_args () {
    local __doc__="""evalute the args to the wee function by type, not position"""
    local _arg=
    for _arg in "$@"; do
        if _is_script_name $_arg; then
            path_to_file="$_arg"
        elif _is_number $_arg; then
            history_index=$_arg
        elif _is_identifier $_arg; then
            is_executable $_arg && return 1
            function=$_arg
        fi
    done
}

_write_new_file () {
    local __doc__="""Copy the head of this script to file"""
    head -n $_heading_lines $BASH_SOURCE > "$path_to_file"
}

_create_function () {
    local __doc__="""Make a new function with a command in shell history"""
    local doc="copied from $(basename $SHELL) history on $(date)"
    local history_command=$(_show_history_command)
    eval "$function() { local __doc__="""$doc"""; $history_command; }" 2>/dev/null
}

_make_path_to_file_exist () {
    local __doc__="""make sure the required file exists, either an existing file, a new file, or a temp file"""
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

is_executable () {
    local __doc__="""Whether the name is in use as an alias, executable, ..."""
    if is-existing-function "$1"; then
        return 1
    else type "$1" 2>/dev/null
    fi
}

_show_history_command () {
    local __doc__="""Get a command from the end of current bash history"""
    local line=
    local words=$(fc -ln -$history_index -$history_index)
    for word in $words
    do
        if [[ ${word:0:1} != "-" ]]; then
            is-existing-alias $word && word="\\$word"
        fi
        [[ -z $line ]] && line=$word || line="$line $word"
    done
    echo $line
}

_is_script_name () {
    local __doc__="""Whether the first argument ends in .sh, or is a file"""
    [[ "$1" =~ \.sh$ || -f "$1" ]]
}

_is_identifier () {
    local __doc__="""Whether the first argument is alphanumeric and underscores"""
    [[ "$1" =~ ^[[:alnum:]_]+$ ]]
}

_debug_declare_function () {
    local __doc__="""Find where the first argument was loaded from"""
    shopt -s extdebug
    declare -F "$1"
    shopt -u extdebug
}

__parse_function_line_number_and_path_to_file () {
    local __doc__="""extract the ordered arguments from a debug declare"""
    function="$1";
    shift;
    line_number="$1";
    shift;
    path_to_file="$*";
}

source-path () {
    test -f "$1" || return 1
    whyp-source "$@" 
}

is-existing-function () {
    local __doc__="""Whether the first argument is in use as a function"""
    [[ "$(type -t $1)" == "function" ]]
}

is-existing-alias () {
    local __doc__="""Whether the first argument is in use as a alias"""
    [[ "$(type -t $1)" == "alias" ]]
}

[[ -n $WELCOME_BYE ]] && echo Bye from $(basename "$BASH_SOURCE") in $(dirname $(readlink -f "$BASH_SOURCE")) on $(hostname -f)
