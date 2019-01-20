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

WHYP_SOURCE=$BASH_SOURCE
export WHYP_DIR=$(dirname $(readlink -f $WHYP_SOURCE))
export WHYP_BIN=$WHYP_DIR/bin
export WHYP_PY=$WHYP_DIR/whyp
export WHYP_OUT=$WHYP_DIR/whyp.out
export WHYP_ERR=$WHYP_DIR/whyp.err

whyp-bin () {
    local __doc__="""Full path to a script in whyp/bin"""
    echo $WHYP_BIN/"$1"
}

whyp-bin-run () {
    local __doc__="""Run a script in whyp/bin"""
    local _script=$1; shift
    PYTHONPATH=$WHYP_DIR $(whyp-bin $_script) "$@"
}

whyp-bin-run sources --clear

# x

alias e=eype
alias w=whyp

# xx

alias wp=whyp-python
alias ww=whyp-whyp

# xxx
alias www="whyp-whyp -v"

# xxxx

# https://www.reddit.com/r/commandline/comments/2kq8oa/the_most_productive_function_i_have_written/
eype () {
    local __doc__="""Edit the first argument as if it's a type"""
    local _sought=
    if whyp-python -q $1; then
        _sought=$1; shift
        _vim_file $(whyp-python $_sought) "$@"
        return 0
    elif [[ $(type -t $1) == "file" ]]; then
        _edit_file $1
    elif is-existing-function $1; then
        _parse_function $1
        _edit_function
    elif is-existing-alias $1; then
        _edit_alias $1
    else
        _file=$1; shift
        _sought=$1; shift
        vim $_file +/$_sought_
    fi
}

# "whap" is for backward compatibility only, remove before v1.0.0
alias whap=whyp-python

whyp () {
    local __doc__="""whyp will extend type, later"""
    type "$@" >$WHYP_OUT 2>$WHYP_ERR
    cat $WHYP_OUT
}

# xxxxx*

whyp-py () {
    whyp-bin-run whyp "$@"
}

whyp-py-file () {
    whyp-bin-run whyp -f "$@"
}

python-has-debugger () {
    [[ $1 =~ ^((3(.[7-9])?)|([4-9](.[0-9])?))$ ]]
}

looks-versiony () {
    [[ ! $1 ]] && return 1
    [[ $1 =~ [0-9](.[0-9])* ]]
}

local-python () {
    # if whyp-executable pyth; then
    #     echo pyth
    #     return 0
    # fi
    local _which_py=python
    if looks-versiony $1; then
        if python-has-debugger $1; then
            _which_py=python$1
        else
            _which_py=python
            echo "Requested python version too old" >&2
        fi
        shift
    fi
    local _exec_py=$(PATH=/usr/local/bin:/usr/bin/:/bin which $_which_py)
    local _interpreter=$(readlink -f "$_exec_py")
    [[ -e $_interpreter ]] && $_interpreter -c "import sys; sys.stdout.write(sys.executable)"
}

whyp-python () {
    local __doc__="""find what python will import for a string, outside virtualenvs"""
    local _quietly=
    [[ $1 == -q ]] && _quietly=-q && shift
    local _python=$(local-python $1)
    local _whyp_python=$(whyp-bin python)
    if [[ -e $_python && -f $_whyp_python ]]; then
        $_python $_whyp_python $_quietly "$@"
        return $?
    else
        [[ -e $_python ]] || echo "$_python is not executable" >&2
        [[ -f $_whyp_python ]] || echo "$_whyp_python is not a file" >&2
        return 1
    fi
}

quietly () {
    "$@" 2>/dev/null
}

Quietly () {
    "$@" >/dev/null 2>&1
}

whyp-whyp () {
    local __doc__="""whyp-whyp expands whyp, now"""
    local _pass=0
    local _fail=1
    [[ "$@" ]] || return $_fail
    local _options=-v
    if [[ $1 =~ -[qv] ]]; then
        _options=$1
        shift
    fi
    local _whyp=$(quietly whyp "$@")
    if [[ $? != $_pass ]]; then
        # whyp "$@"
        cat $WHYP_ERR
        return $_fail
    fi
    if [[ $(type -t "$1") == "file" ]]; then
        w "$@"
        ls -l "$1"
        return $_pass
    fi
    # show-command $_options "$@" && return $_pass
    # [[ $_options == -q ]] && return $_fail
    # [[ $_options == -v ]] && echo "$@ not whypped" >&2
    return $_fail
}

show-command () {
    local _arg=$1;
    if [[ $_arg =~ -[vq] ]]; then
        shift
        if [[ $_arg =~ -[q] ]]; then
            Quietly whyp-command "$@"
            return $?
        fi
    fi
    whyp-command "$@"
}

whyp-command () {
    local __doc__="""find what will be executed for a command string"""
    PATH_TO_ALIASES=/tmp/aliases
    PATH_TO_FUNCTIONS=/tmp/functions
    alias > $PATH_TO_ALIASES
    declare -f > $PATH_TO_FUNCTIONS
    whyp-py --aliases=$PATH_TO_ALIASES --functions=$PATH_TO_FUNCTIONS "$@";
    # local return_value=$?
    # rm -f $PATH_TO_ALIASES
    # rm -f $PATH_TO_FUNCTIONS
    # return $return_value
}

whyp-debug () {
    (DEBUGGING=www;
        local _command="$1"; shift
        ww $_command;
        whyp $_command;
        (set -x; $_command "$@" 2>&1 )
    )
}

_edit_alias () {
    local __doc__="""Edit an alias in the file $ALIASES, if that file exists"""
    whyp-bin-run sources --any || return
    OLD_IFS=$IFS
    local _whyp_sources=$(whyp-bin-run sources --files)
    IFS=:; for sourced_file in $_whyp_sources; do
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
    [[ -f $_file ]] || return 1
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


source-whyp () {
    local __doc__="""Source a file (that may set some aliases) and remember that file"""
    local _filename=$(readlink -f "$1")
    if [ -z "$_filename" -o ! -f "$_filename" ]; then
        if [[ -z $2 || $2 != "optional" ]]; then
            echo Cannot source \"$1\". It is not a file. >&2
        fi
        return
    fi
    whyp-bin-run sources --optional --sources "$_filename"
    if whyp-bin-run sources --found "$_filename"; then
        source "$_filename"
    fi
}

quietly unalias .
alias .=source-whyp


# _xxxxx+

whyp-executable () {
    Quietly type "$@"
}

whyp-function () {
    _parse_function "$@"
    echo "$function is at '$path_to_file:$line_number'"
    echo "$EDITOR $path_to_file +$line_number"
}

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
    elif whyp-executable "$1"; then
        real_file=$(readlink -f $(which "$1"))
        [[ $real_file != "$1" ]] && echo -n "$1 -> "
        echo "$real_file"
    else type "$1"
    fi
}


# Methods starting with underscores are intended for use in this file only
#   (another convention borrowed from Python)


_write_new_file () {
    local __doc__="""Copy the head of this script to file"""
    head -n $_heading_lines $BASH_SOURCE > "$path_to_file"
}

_create_function () {
    local __doc__="""Make a new function with a command in shell history"""
    local doc="copied from $(basename $SHELL) history on $(date)"
    local history_command=$(_show_history_command)
    quietly eval "$function() { local __doc__="""$doc"""; $history_command; }"
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

_debug_declare_function () {
    local __doc__="""Find where the first argument was loaded from"""
    shopt -s extdebug;
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
