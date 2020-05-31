#! /usr/bin/env head -n 3

# This script is intended to be sourced, not run

if [[ "$0" == $BASH_SOURCE ]]; then
    echo "This file should be run as"
    echo "  source $0"
    echo "and should not be run as"
    echo "  sh $0"
fi
#
license_="This script is released under the MIT license, see accompanying LICENSE file"
#
heading_lines_=13 # Text before here was copied to template scripts, YAGNI


export WHYP_SOURCE=$BASH_SOURCE
export WHYP_DIR=$(dirname $(readlink -f $WHYP_SOURCE))
export WHYP_BIN=$WHYP_DIR/bin
export WHYP_VENV=
[[ -d $WHYP_DIR/.venv ]] && WHYP_VENV=$WHYP_DIR/.venv
[[ -d $WHYP_VENV ]] || WHYP_VENV=~/.virtualenvs/whyp
export WHYP_PY=$WHYP_DIR/whyp

# x

# https://www.reddit.com/r/commandline/comments/2kq8oa/the_most_productive_function_i_have_written/
e () {
    local __doc__="""Edit the first argument as if it's a type, pass on $@ to editor"""
    local _sought= _file=
    is_bash "$1" && return
    is_file "$1" && _edit_file "$@" && return $?
    if is_function "$1"; then
        _parse_function "$1"
        _edit_function "$@"
        return 0
    fi
    if is_alias "$1"; then
        _edit_alias "$1"
        return 0
    fi
    python_will_import "$1" && _file=$(python_module "$1") || _file="$1"; shift
    _sought="$1"; shift
    whyp_edit_file "$_file" +/"$_sought" "$@"_
}

w () {
    local __doc__="""w extends type"""
    [[ "$@" ]] || echo "Usage: w <command>"
    # -a, --all
    local _alls_regexp="--*[al]*" options_=
    [[ "$1" =~ $_alls_regexp ]] && options_=--all
    [[ $options_ ]] && shift
    if is_file "$@"; then
        type "$@"
        echo
        which $options_ "$@" 2>/dev/null
        return 0
    else
        type "$@" 2>/dev/null || /usr/bin/env | grep --colour "$@"
    fi
    ww "$@"
}

alias .=ws

# xx

[[ $ALIAS_CC ]] && alias cc=e
alias .w=dot_w
alias wa='w --all'

ws () {
    local __doc__="""Source a file (that may set some aliases) and remember that file"""
    local _filename=$(readlink -f "$1") _optional=
    [[ $2 == "optional" ]] && _optional=1
    if [[ -f $_filename ]]; then
      source $_filename
      return 1
    fi
    [[ -f $_filename || $_optional ]] || echo Cannot source \"$1\". It is not a file. >&2
    [[ -f $_filename ]] || return
    source "$_filename"
}

wq () {
    quietly w "$@"
}

ww () {
    local __doc__="""ww expands type"""
    [[ "$@" ]] || return 1
    local _whyp_options=$(ww_option "$@")
    [[ $_whyp_options ]] && shift
    local _name="$1"; shift
    ww_show "$_name"
    [[ $? == 0 ]] && return 0
}

alias .w="ws $WHYP_SOURCE"

# xxx

ses () {
    if [[ $1 == -e ]]; then
        sed "$@"
    else
        sed -e "s,$1,$2",
    fi
}

wat () {
    local _cmd=cat
    is_file kat && _cmd=kat
    is_file bat && _cmd=bat
    $_cmd "$@"
}
# xxxx

whyp () {
  w "$@"
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
    sed -e "/is aliased to \`/s:.$::" -e "s:.* is aliased to [\`]*::"
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
    de_hashed $(quietly w "$@") | de_file | de_alias
}

deafened () {
    echo $(de_hashed $(wq "$@")) | de_alias | de_file
}

defended () {
    $( "$@") | de_alias | de_file
}

runnable () {
    QUIETLY type "$@"
}

ww_executable () {
    QUIETLY type $(deafened "$@")
}

# xxxxx
dot_w () {
    . $WHYP.sh
}

# xxxxx*

ww_bin () {
    local __doc__="""Full path to a script in whyp/bin"""
    echo $WHYP_BIN/"$1"
}

whyp_bin_run () {
    local __doc__="""Run a script in whyp/bin"""
    local _script=$(ww_bin $1); shift
    if [[ -d $WHYP_VENV ]]; then
        (
            source "$WHYP_VENV/bin/activate"
            PYTHONPATH=$WHYP_DIR $_script "$@"
        )
    else
        PYTHONPATH=$WHYP_DIR $_script "$@"
    fi
}

whyp_pudb_run () {
    local __doc__="""Debug a script in whyp/bin"""
    local _script=$(ww_bin $1); shift
    set -x
    PYTHONPATH=$WHYP_DIR pudb $_script "$@"
    set +x
}

ww_py () {
    python3 -m whyp "$@"
}

whyp_py_file () {
    python3 -m whyp -f "$@"
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

ww_option () {
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

looks_like_python_name () {
    local __doc__="""Whether arg looks like a python name"""
    # Python names do not start with numbers
    [[ $1 =~ ^[0-9] ]] && return 1
    # Python names do not have hyphens, nor code
    [[ $1 =~ [-/] ]] && return 1
    return 0
}

python_will_import () {
    local __doc__="""test that python will import any args"""
    for arg in "$@"; do
        looks_like_python_name $arg || continue
        python -c "import $arg" >/dev/null 2>&1 || return 1
    done
    return 0
}

python_module () {
    local __doc__="""the files that python imports args as"""
    local _result=1
    for arg in "$@"; do
        looks_like_python_name $arg || continue
        python -c "import $arg; print($arg.__file__)" 2>/dev/null || continue
        _result=0
    done
    return $_result
}

python_module_version () {
    local __doc__="""the installed version of that python package"""
    local _result=1 _arg=
    for _arg in "$@"; do
        python_will_import $_arg || continue
        python -c "import $_arg; module=$_arg; print(f'{module.__file__}: {module.__version__}')" 2>/dev/null || continue
        _result=0
    done
    return $_result
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

wat () {
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
    [[ $1 ]] || return 0
    _lines=$(wc -l "$1" | sed -e "s, .*,," 2>/dev/null)
    [[ $_lines == 0 ]] || return 0
    set -x
    rri "$1"
    set +x
}


ww_bash () {
    local __doc__="""help on bash builtin"""
    is_bash "$@" || return 1
    help "$@"
    return 0
}

ww_function () {
    local __doc__="""whyp a function"""
    is_function "$@" || return 1
    _parse_function "$@"
    [[ -f $path_to_file ]] || return 1
    type $1 | sed -e "/is a function$/d" | wat
    echo "'$path_to_file:$line_number' $function ()"
    echo "$EDITOR $path_to_file +$line_number"
    return 0
}

ww_alias () {
    is_alias "$@" || return 1
    alias $1
    local _stdout=$(alias $1)
    if [[ $_stdout  =~ is.a.function ]]; then
        _name=$(defended $_name)
        ww_function $_name
    else
        local _suffix=${_stdout//*=\'}
        local _command=${_suffix//\'}
        w $_command
    fi
}

ww_file () {
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

ww_args () {
    local _arg= _option= _shifts=
    for _arg in "$@"; do
        [[ $_arg == -v ]] && _option=-v
        [[ $_arg == verbose ]] && _option=-v
        [[ $_arg == -q ]] && _option=-q
        [[ $_arg == quiet ]] && _option=-q
        [[ $_arg == -vv ]] && _option=-v
        [[ $_option ]] || continue
        WOPTS=$_option
        echo $_arg
    done
}

whyp_show_ () {
    WOPTS=
    local _shower=quietly _args=$(ww_args "$@") _arg= _name= _type=
    [[ $WOPTS == -v ]] && _shower=
    for _arg in $_args; do
        _name="$_arg"; shift
        _type="$_shower $_arg"; shift
        $_type
    done
    return 0
}

ww_show () {
    local _whyp_= _name="$1"
    shift
    for whyp_ in ww_bash ww_function ww_alias ww_file ; do
        whyp_show_ $_name $whyp_ || continue
        return 0
    done
    return 1
}

ww_command () {
    local __doc__="""find what will be executed for a command string"""
    PATH_TO_ALIASES=/tmp/aliases
    PATH_TO_FUNCTIONS=/tmp/functions
    alias > $PATH_TO_ALIASES
    declare -f > $PATH_TO_FUNCTIONS
    ww_py --aliases=$PATH_TO_ALIASES --functions=$PATH_TO_FUNCTIONS "$@";
    # local return_value=$?
    # rm -f $PATH_TO_ALIASES
    # rm -f $PATH_TO_FUNCTIONS
    # return $return_value
}

ww_debug () {
    (DEBUGGING=www;
        local _command="$1"; shift
        ww $_command;
        w $_command;
        (set -x; $_command "$@" 2>&1 )
    )
}

_edit_alias () {
    local __doc__="""Edit an alias in the file $ALIASES, if that file exists"""
    _sources --any || return
    local _whyp_sources=$(_sources --all --optional)
    for sourced_file in $_whyp_sources; do
        [[ -f $sourced_file ]] || continue
        line_number=$(grep -nF "alias $1=" $sourced_file | cut -d ':' -f1)
        if [[ -n "$line_number" ]]; then
            whyp_edit_file $sourced_file +$line_number
            return 0
        fi
    done
    echo "Did not find a file with '$1'" >&2
    return 1
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
    [[ "$@" =~ [+][/] ]] && _seek=$(echo "$@" | ses ".*\([+][/][^ ]*\).*" "\1")
    whyp_edit_file "$path_to_file" $_line $_seek
    test -f "$path_to_file" || return 0
    ls -l "$path_to_file"
    ww_source "$path_to_file"
    [[ $(basename $(dirname "$path_to_file")) == tmp ]] && rm -f "$path_to_file"
    return 0
}

_edit_file () {
    local __doc__="""Edit a file, it is seems to be text, otherwise tell user why not"""
    local _file=$(ww_py $1)
    [[ -f $_file ]] || return 1
    if file $_file | grep -q text; then
        whyp_edit_file  $_file
    else
        echo $_file is not text >&2
        file $_file >&2
    fi
}

ww_source () {
    local __doc__="""Source optionally"""
    ws "$@" optional
}


quietly unalias .


# _xxxxx+

www_ () {
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


_sources () {
    whyp_bin_run sources "$@"
}

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
    shopt -s extdebug
    declare -F "$1"
    shopt -u extdebug
}

ddf () {
    local __doc__="""where the arg came from"""
    ( shopt -s extdebug; declare -F "$1" )
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
