#! /usr/bin/env head -n 3

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
_heading_lines=13 # Text before here was copied to template scripts, YAGNI


export WHYP_SOURCE=$BASH_SOURCE
export WHYP_DIR=$(dirname $(readlink -f $WHYP_SOURCE))
export WHYP_BIN=$WHYP_DIR/bin
export WHYP_VENV=
[[ -d $WHYP_DIR/.venv ]] && WHYP_VENV=$WHYP_DIR/.venv
export WHYP_PY=$WHYP_DIR/whyp

# x

alias e=eype
alias w=whyp

# xx

[[ $ALIAS_CC ]] && alias cc=eype
alias wa='whyp --all'
alias ww=whyp_whyp

# xxx

alias wat=whyp_cat
alias www=whyp_whyp_whyp

ses () {
    local _old="$1"; shift
    local _new="$1"; shift
    echo "$@" | sed -e "s:$_old:$_new:"
}

wat () {
    local _cmd=cat
    is_file bat && _cmd=bat
    is_file kat && $(kat "$@" >/dev/null 2>&1) && _cmd=kat
    $_cmd "$@"
}
# xxxx

# https://www.reddit.com/r/commandline/comments/2kq8oa/the_most_productive_function_i_have_written/
eype () {
    local __doc__="""Edit the first argument as if it's a type, pass on $@ to editor"""
    local _sought=
    is_bash "$1" && return
    is_file "$1" && _edit_file "$@" && return $?
    if is_function "$1"; then
        _parse_function "$1"
        _edit_function "$@"
    elif is_alias "$1"; then
        _edit_alias "$1"
    elif whypy "$1"; then
        _sought="$1"; shift
        whyp_edit_file $(whypyf $1) +/"$_sought" "$@"
        return 0
    else
        local _file="$1"; shift
        _sought="$1"; shift
        whyp_edit_file "$_file" +/"$_sought" "$@"_
    fi
}

ww_help () {
    local _function=$1; shift
    rm -f /tmp/err
    [[ $1 =~ (-h|--help) ]] && ww $_function 2>/tmp/err
    local _result=$?
    [[ -f /tmp/err ]] && return 2
    return $_result
}

de_alias () {
    sed -e "s:.* is aliased to::"
}

de_file () {
    sed -e "s:[^ ]* is ::"
}

de_hashed () {
    local _command=$1
    local _type="$@"
    if [[ $_type =~ hashed ]]; then
        local _dehash=$(echo $_type | sed -e "s:.*hashed (\([^)]*\)):\1:")
        _type="$_command is $_dehash"
    fi
    echo $_type
}

de_typed () {
    de_hashed $(quietly whyp "$@") | de_file | de_alias
}

whyp () {
    local __doc__="""whyp extends type"""
    [[ "$@" ]] || echo "Usage: whyp <command>"
    local _alls_regexp="--*[al]*\>"
    if [[ "$@" =~ $_alls_regexp ]]; then
        local _command=$(echo "$@" | sed -e "s:$_alls_regexp::" )
        ( type $_command
        which -a "$_command" )
    else
        type "$@"
    fi
}

whysp () {
    quietly whyp "$@"
}

whyped () {
    echo $(de_hashed $(whysp "$@")) | de_alias | de_file
}

whypped () {
    $(whyped "$@") | de_alias | de_file
}

runnable () {
    QUIETLY type "$@"
}

whyp_executable () {
    QUIETLY type $(whyped "$@")
}

# xxxxx*

whyp_bin () {
    local __doc__="""Full path to a script in whyp/bin"""
    echo $WHYP_BIN/"$1"
}

whyp_bin_run () {
    local __doc__="""Run a script in whyp/bin"""
    local _script=$1; shift
    if [[ -d $WHYP_VENV ]]; then
        (
            source "$WHYP_VENV/bin/activate"
            python whyp_bin $_script "$@"
        )
    else
        PYTHONPATH=$WHYP_DIR $(whyp_bin $_script) "$@"
    fi
}

whyp_pudb_run () {
    local __doc__="""Debug a script in whyp/bin"""
    local _script=$1; shift
    set -x
    PYTHONPATH=$WHYP_DIR pudb $(whyp_bin $_script) "$@"
    set +x
}

whyp_py () {
    whyp_bin_run whyp "$@"
}

whyp_py_file () {
    whyp_bin_run whyp -f "$@"
}

whyp_edit_file () {
    local __doc__="""Edit the first argument if it's a file"""
    local _file=$1; shift
    [[ -f $_file ]] || return 1
    local _dir=$(dirname $_file)
    [[ -d $_dir ]] || _dir=.
    local _base=$(basename $_file)
    (cd $_dir; $EDITOR $_base "$@")
}

python_has_debugger () {
    [[ $1 =~ ^((3(.[7-9])?)|([4-9](.[0-9])?))$ ]]
}

looks_versiony () {
    [[ ! $1 ]] && return 1
    [[ $1 =~ [0-9](.[0-9])* ]]
}

local_python () {
    local _local_python_name=python
    if looks_versiony $1; then
        if python_has_debugger $1; then
            _local_python_name=python$1
        else
            _local_python_name=python2
            echo "Requested python version too old" >&2
        fi
        shift
    else
        _local_python_name=python3
    fi
    local _local_python=$(PATH=/usr/local/bin:/usr/bin/:/bin which $_local_python_name 2>/dev/null)
    [[ $_local_python ]] && $_local_python -c "import sys; sys.stdout.write(sys.executable)"
}

whyp_option () {
    local _options=
    [[ $1 == -q ]] && _options=quiet
    [[ $1 == -v ]] && _options=verbose
    [[ $1 == verbose ]] && _options=verbose
    [[ $1 == quiet ]] && _options=quiet
    [[ $1 == -f ]] && _options="$_options --is-function"
    [[ $1 == -a ]] && _options="$_options --is-alias"
    [[ $_options ]] || return 1
    echo $_options
    return 0
}

whypy () {
    local __doc__="""test that python will import any args"""
    for arg in "$@"; do
        whypyn $arg || continue
        python -c "import $arg" >/dev/null 2>&1 || return 1
    done
    return 0
}

whypyf () {
    local __doc__="""the files that python imports args as"""
    local _result=1
    for arg in "$@"; do
        whypyn $arg || continue
        python -c "import $arg; print($arg).__file__" 2>/dev/null || continue
        _result=0
    done
    return $_result
}

whypyn () {
    local __doc__="""Whether arg looks like a python name"""
    # Python names do not start with numbers
    [[ $1 =~ ^[0-9] ]] && return 1
    # Python names do not have hyphens, nor code
    [[ $1 =~ [-/] ]] && return 1
    return 0
}

quietly () {
    "$@" 2>/dev/null
}

quiet_out () {
    "$@" >/dev/null
}

QUIETLY () {
    "$@" >/dev/null 2>&1
}

make_shebang () {
    sed -e "1s:.*:#! /bin/bash:"
}

whyp_cat () {
    local __doc__="""Choose best avalaible cat"""
    local __todo__="""Add vimcat, kat, pygments, ..."""
    local _lines=
    if [[ $1 =~ ^[0-9]+$ ]]; then
        _lines=$1
        shift
    fi
    if runnable bat; then
        bat --language=bash --style=changes,grid,numbers "$@"
    elif runnable kat; then
        kat --numbers "$@"
    elif [[ $_lines > 40 ]]; then
        less "$@"
    else
        cat "$@"
    fi
}


whyp_bash () {
    local __doc__="""help on bash builtin"""
    is_bash "$@" || return 1
    help "$@"
    return 0
}

whyp_function () {
    local __doc__="""whyp a function"""
    is_function "$@" || return 1
    _parse_function "$@"
    [[ -f $path_to_file ]] || return 1
    local _lines=$(type $1 | wc -l)
    type $1 | sed -e "/is a function$/d" | whyp_cat $_lines
    echo "'$path_to_file:$line_number' $function ()"
    echo "$EDITOR $path_to_file +$line_number"
    return 0
}

whyp_alias () {
    is_alias "$@" || return 1
    alias $1
    local _stdout=$(alias $1)
    if [[ $_stdout  =~ is.a.function ]]; then
        _name=$(whypped $_name)
        whyp_function $_name
    else
        local _suffix=${_stdout//*=\'}
        local _command=${_suffix//\'}
        whyp $_command
    fi
}

whyp_file () {
    is_file "$@" || return 1
    local _path=$(type "$1" | sed -e "s:.* is ::")
    local _command=less
    runnable bat && _command=bat
    $_command $_path
    ls -l $_path
    return $_pass
}

is_type () {
    local _is_type=$1
    local _thing="$2"
    $_is_type "$_thing" && return 0
    return 1
}

whyp_option () {
    local _options=
    [[ $1 == -q ]] && _options=quiet
    [[ $1 == -v ]] && _options=verbose
    [[ $1 == verbose ]] && _options=verbose
    [[ $1 == quiet ]] && _options=quiet
    [[ $_options ]] || return 1
    echo $_options
    return 0
}

whyp_show_ () {
    local _stream=quietly
    local _options=$(whyp_option "$@")
    [[ $_options ]] && shift
    [[ $_options == verbose ]] && _stream=
    local _name="$1"; shift
    local _type="$_stream $1"; shift
    $_type "$_name" || return 1
    return 0
}

whyp_show () {
    local _name=$1; shift
    local _shown=
    local _whyp=
    for _whyp in whyp_bash whyp_function whyp_alias whyp_file ; do
        whyp_show_ $_name $_whyp || continue
        return 0
    done
    return 1
}

whyp_whyp () {
    local __doc__="""whyp_whyp expands whyp, now"""
    [[ "$@" ]] || return 1
    local _whyp_options=$(whyp_option "$@")
    [[ $_whyp_options ]] && shift
    [[ $1 ]]
    local _name="$1"; shift
    whyp_show "$_name"
    [[ $? == 0 ]] && return 0
}

whyp_command () {
    local __doc__="""find what will be executed for a command string"""
    PATH_TO_ALIASES=/tmp/aliases
    PATH_TO_FUNCTIONS=/tmp/functions
    alias > $PATH_TO_ALIASES
    declare -f > $PATH_TO_FUNCTIONS
    whyp_py --aliases=$PATH_TO_ALIASES --functions=$PATH_TO_FUNCTIONS "$@";
    # local return_value=$?
    # rm -f $PATH_TO_ALIASES
    # rm -f $PATH_TO_FUNCTIONS
    # return $return_value
}

whyp_debug () {
    (DEBUGGING=www;
        local _command="$1"; shift
        ww $_command;
        whyp $_command;
        (set -x; $_command "$@" 2>&1 )
    )
}

_edit_alias () {
    local __doc__="""Edit an alias in the file $ALIASES, if that file exists"""
    whyp_bin_run sources --any || return
    local _whyp_sources=$(whyp_bin_run sources --all --optional)
    for sourced_file in $_whyp_sources; do
        [[ -f $sourced_file ]] || continue
        line_number=$(grep -nF "alias $1=" $sourced_file | cut -d ':' -f1)
        if [[ -n "$line_number" ]]; then
            whyp_edit_file $sourced_file +$line_number
        fi
    done
}

_edit_function () {
    local __doc__="""Edit a function in a file"""
    local _made=
    _make_path_to_file_exist && _made=1
    local _regexp="^$function[[:space:]]*()[[:space:]]*{[[:space:]]*$"
    local _new=
    if ! grep -q $_regexp "$path_to_file"; then
        line_number=$(wc -l "$path_to_file")
        echo "Add $function onto $path_to_file at new line $line_number"
        set +x; return 0
    fi
    local _line=; [[ -n "$line_number" ]] && _line=+$line_number
    local _seek=+/$_regexp
    [[ "$@" =~ [+][/] ]] && _seek=$(ses ".*\([+][/][^ ]*\).*" '\1' "$@")
    whyp_edit_file "$path_to_file" $_line $_seek
    test -f "$path_to_file" || return 0
    ls -l "$path_to_file"
    whyp_source "$path_to_file"
    [[ $(basename $(dirname "$path_to_file")) == tmp ]] && rm -f "$path_to_file"
    return 0
}

_edit_file () {
    local __doc__="""Edit a file, it is seems to be text, otherwise tell user why not"""
    local _file=$(whyp_py $1)
    [[ -f $_file ]] || return 1
    if file $_file | grep -q text; then
        whyp_edit_file  $_file
    else
        echo $_file is not text >&2
        file $_file >&2
    fi
}

whyp_source () {
    local __doc__="""Source optionally"""
    source_whyp "$@" optional
}


source_whyp () {
    local __doc__="""Source a file (that may set some aliases) and remember that file"""
    local _filename=$(readlink -f "$1")
    if [ -z "$_filename" -o ! -f "$_filename" ]; then
        if [[ -z $2 || $2 != "optional" ]]; then
            echo Cannot source \"$1\". It is not a file. >&2
        fi
        return 1
    fi
    if whyp_bin_run sources --optional --sources "$_filename"; then
        source "$_filename"
    fi
}

quietly unalias .
alias .=source_whyp


# _xxxxx+

whyp_whyp_whyp () {
    ww verbose "$@"
}

_parse_function () {
    __parse_function_line_number_and_path_to_file $(_debug_declare_function "$1")
}

old_whyp_type () {
    if is_alias "$1"; then
        type "$1"
    elif is_function "$1"; then
        type "$1"
        echo
        local _above=$(( $line_number - 1 ))
        echo "whyp_edit_file $(relpath ""$path_to_file"") +$_above +/'\\<$function\\zs.*'"
    elif whyp_executable "$1"; then
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
    [[ ! "$path_to_file" || $path_to_file == main ]] && path_to_file=$(mktemp /tmp/function.XXXXXX)
    _write_new_file "$path_to_file"
}

_vim_line () {
    local _file="$1";shift
    local _line="$1";shift
    whyp_edit_file  "$_file" +$line
}

_show_history_command () {
    local __doc__="""Get a command from the end of current bash history"""
    local line=
    local words=$(fc -ln -$history_index -$history_index)
    for word in $words
    do
        if [[ ${word:0:1} != "-" ]]; then
            is_alias $word && word="\\$word"
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

source_path () {
    test -f "$1" || return 1
    whyp_source "$@"
}

is_alias () {
    local __doc__="""Whether $1 is an alias"""
    [[ "$(type -t $1)" == "alias" ]]
}

is_function () {
    local __doc__="""Whether $1 is a function"""
    [[ "$(type -t $1)" == "function" ]]
}

is_bash () {
    local __doc__="""Whether the first argument is a keyword or builtin"""
    is_keyword $1 || is_builtin $1
}

is_keyword () {
    local __doc__="""Whether $1 is a keyword"""
    [[ "$(type -t $1)" == "keyword" ]]
}

is_builtin () {
    local __doc__="""Whether $1 is a builtin"""
    [[ "$(type -t $1)" == "builtin" ]]
}

is_file () {
    local __doc__="""Whether $1 is an executable file"""
    [[ "$(type -t $1)" == "file" ]]
}

is_unrecognised () {
    local __doc__="""Whether $1 is unrecognised"""
    [[ "$(type -t $1)" == "" ]]
}
