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


export WHYP_SOURCE=$(readlink -f $BASH_SOURCE)
export WHYP_DIR=$(dirname $WHYP_SOURCE)
export WHYP_EDITOR=
export WHYP_PY=$WHYP_DIR/whyp

# x

# https://www.reddit.com/r/commandline/comments/2kq8oa/the_most_productive_function_i_have_written/clo0gh2/
e () {
    local __doc__="""Edit the first argument as if it's a type, pass on $@ to editor"""
    if is_alias "$1"; then
        edit_alias_ "$1"
        return 0
    fi
    if is_function "$1"; then
        parse_function_ "$1"
        edit_function_ "$@"
        return 0
    fi
    is_file "$1" && edit_file_ "$@" && return $?
    is_bash "$1" && return 1
    local file_="$1"
    is_python_module "$1" && file_=$(python_module "$1")
    shift
    local search_=
    [[ "$@" ]] && search_='+/'"$@"
    whyp_edit_file "$file_" "$search_"
}

w () {
    local __doc__="""whyp args or w"""
    [[ "$@" ]] || ww w
    whyp "${@}"
}

alias .=whyp_source

# xx

alias wq="quietly whyp "

ww () {
    local __doc__="""ww extends whyp"""
    [[ "$@" ]] || ww ww
    local options_=$(quietly whyp_option "$@")
    [[ $options_ ]] && shift
    local name_=$1
    while [[ "$name_" ]]; do
        [[ $options_ =~ -v ]] && w $name_
        ww_show $name_
        shift
        name_=$1
    done
}


# xxx

ses () {
    local __doc__="""Substitute $2 for $1"
    sed -e "s,$1,$2",
}

wat () {
    local __doc__="""Choose best avalaible cat"""
    local __todo__="""Add vimcat, kat, pygments, ..."""
    local lines_=
    if [[ $1 =~ ^[0-9]+$ ]]; then
        lines_=$1
        shift
    fi
    if runnable bat; then
        bat --language=bash --style=changes,grid,numbers "$@"
    elif runnable kat; then
        kat --numbers "$@"
    elif [[ $lines_ > 40 ]]; then
        less "$@"
    else
        cat "$@"
    fi
    [[ $1 ]] || return 0
    lines_=$(quietly wc -l "$1" | sed -e "s, .*,," )
    [[ $lines_ == 0 ]] || return 0
    what_no_args_are you_mad
}

# xxxx

QYPE () {
    QUIETLY type "$@"
}

Qype () {
    Quietly type "$@"
}

qype () {
    quietly type "$@"
}

qich () {
    quietly which "$@"
}

west () {
    QUIETLY test "$@"
}

whyp () {
    local __doc__="""whyp extends type"""
    if [[ ! "$@" ]]; then
        ww whyp
        echo
        echo "Usage: whyp [-v] <command>"
        return 1
    fi

    local name_="$1" verbose_=
    shift
    if [[ $name_ == -v ]]; then verbose_=1; shift; fi
    if is_alias $name_; then
        alias $name_
        whyp $(dealias $name_)
    elif is_function "$name_"; then
        qype "$name_" | grep -v ' is a '
        parse_function_ "$name_"
        echo
        [[ $verbose_ ]] && echo "$EDITOR $path_to_file +$line_number" && echo
    elif is_file "$name_"; then
        local typed_=$(qype "$name_")
        local file_=$(qich "$name_")
        if [[ ! $file_ ]]; then
            [[ $verbose_ ]] && echo $typed_
            return 1
        fi
        local real_=$(readlink -f "$file_")
        local out_="$file_"
        [[ "$file_" == "$real_" ]] || out_="$file_ -> $real_"
        echo "$out_"
        [[ $verbose_ ]] && echo "$EDITOR $file_"
        return 0
    else
        runnable "$@" || /usr/bin/env | grep --colour "$@.*="
    fi
}

# xxxxx

ww_py () {
    whyp_bin_run whyp "$@"
}

# xxxxxx

ww_help () {
    local command_=$1; shift
    rm -f /tmp/out /tmp/err
    [[ $command_ =~ (-w|--ww) ]] && ww $function_ 2>/tmp/err
    if [[ $command_ =~ (-h|--help) ]]; then
        if is_builtin $command_; then help $comand_
        elif is_file  $command_; then $command_ --help
        elif is_function $command_; then ww $command_
        elif is_alias $command_; then ww $command_
        fi
    fi >/tmp/out 2>/tmp/err
    local result_=$?
    [[ -f /tmp/err ]] && return 1
    return $result_
}

# xxxxxxx+

Quietly () {
    "$@" > /dev/null
}

quietly () {
    "$@" 2>/dev/null
}

QUIETLY () {
    "$@" > /dev/null 2>/dev/null
}

dealias () {
    alias $1 | sed -e "s,alias \([a-z][a-z_]*\)='\(.*\).$,\2,"
}

de_file () {
    sed -e "s:[^ ]* is ::"
}

de_hashed () {
    local command_=$1; shift
    local type_="$(qype $command_)"
    if [[ $type_ =~ hashed ]]; then
        local dehash_=$(echo $type_ | sed -e "s:.*hashed (\([^)]*\)):\1:")
        type_="$command_ is $dehash_"
    fi
    echo $type_
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
    QYPE "$@"
}

whyp_optional () {
    [[ $1 == -o ]] && return 0
    [[ $1 == --optional ]] && return 0
    [[ $1 == optional ]] && return 0
    return 1
}

whyp_source () {
    local __doc__="""Source a file (that may set some aliases) and remember that file"""
    if [[ ! "$@" ]]; then
        echo "Usage: whyp_source <filename>" >&2
        return 1
    fi
    if [[ -f "$1" ]]; then
        # Note - DO NOT change the "$@" back to "$1" here - source CAN pass on args
        quietly source "$@"
        return 0
    fi
    whyp_optional $2 || echo 'Cannot source "'"$2"'". It is not a file.' >&2
    return 1
}

ww_executable () {
    QUIETLY type $(deafened "$@")
}

ww_bin () {
    local __doc__="""Full path to a script in whyp/bin"""
    echo "$WHYP_DIR/bin/$1"
}

whyp_venv_app () {
    local app_="$1" venv_dir_=$WHYP_DIR/.venv
    [[ -d $venv_dir_ ]] || venv_dir_=~/.virtualenvs/whyp
    [[ -f "$venv_dir_/bin/$1" ]] && app_="$venv_dir_/bin/$1"
    echo $app_
}

whyp_bin_run () {
    local __doc__="""Run a script in whyp/bin"""
    local script_=$(ww_bin $1); shift
    if [[ -d $WHYP_VENV ]]; then
        (
            source "$WHYP_VENV/bin/activate"
            PYTHONPATH=$WHYP_DIR $script_ "$@"
        )
    else
        PYTHONPATH=$WHYP_DIR $script_ "$@"
    fi
}

whyp_pudb_run () {
    local __doc__="""Debug a script in whyp/bin"""
    local script_=$(ww_bin $1); shift
    PYTHONPATH=$WHYP_DIR pudb3 $script_ "$@"
}

whyp_py_file () {
    python3 -m whyp -f "$@"
}

whyp_edit_file () {
    local __doc__="""Edit the first argument if it's a file"""
    local file_="$1"; shift
    [[ -f "$file_" ]] || return 1
    local dir_=$(dirname "$file_")
    [[ -d "$dir_" ]] || dir_=.
    local filename_=$(basename "$file_")
    local editor_="${WHYP_EDITOR:-vim}"
    [[ -x $EDITOR ]] && editor_=$EDITOR
    (cd "$dir_"; "$editor_" "$filename_" "$@")
}

python_has_debugger () {
    [[ $1 =~ ^((3(.[7-9])?)|([4-9](.[0-9])?))$ ]]
}

looks_versiony () {
    [[ ! $1 ]] && return 1
    [[ $1 =~ [0-9](.[0-9])* ]]
}

whyp_option () {
    local options_=
    [[ $1 == -q ]] && options_=quiet
    [[ $1 == -v ]] && options_=verbose
    [[ $1 == verbose ]] && options_=verbose
    [[ $1 == quiet ]] && options_=quiet
    [[ $1 == -f ]] && options_="$options_ --is-function"
    [[ $1 == -a ]] && options_="$options_ --is-alias"
    [[ $options_ ]] || return 1
    echo $options_
    return 0
}

looks_like_python_name () {
    local __doc__="""Whether arg looks like a python name"""
    # Python names do not start with numbers
    [[ $1 =~ ^[0-9] ]] && return 1
    # Python names do not have hyphens, nor slashes
    [[ $1 =~ [-/\\] ]] && return 1
    return 0
}

python_will_import () {
    local __doc__="""test that python will import any args"""
    local python_=${PYTHON:-python}
    for arg in "$@"; do
        looks_like_python_name $arg || continue
        QUIETLY $python_ -c "import $arg" || return 1
    done
    return 0
}

which_python_executable () {
    local python_name_=python
    if looks_versiony $1; then
        if python_has_debugger $1; then
            python_name_=python$1
        else
            python_name_=python2
            echo "Requested python version too old" >&2
        fi
        shift
    else
        python_name_=python3
    fi
    local which_python_=$(qich $python_name_)
    [[ -x "$which_python_" ]] || which_python_=$(quietly PATH=/usr/local/bin:/usr/bin/:/bin which $python_name_)
    [[ -x "$which_python_" ]] && "$which_python_" -c "import sys; sys.stdout.write(sys.executable)"
}

python_executable () {
    local __doc__="""Executable used by python"""
    if [[ -x "$1" ]]; then
        "$1" -c "import sys; sys.stdout.write(sys.executable)"
    else
        which_python_executable "$@"
    fi
}

python_module () {
    local __doc__="""the files that python imports args as"""
    local result_=1
    local python_=${PYTHON:-python}
    for arg in "$@"; do
        looks_like_python_name $arg || continue
        quietly $python_ -c "import $arg; print($arg.__file__)" || continue
        result_=0
    done
    return $result_
}

python_module_version () {
    local __doc__="""the installed version of that python package"""
    local result_=1 arg_=
    local python_=${PYTHON:-python}
    for arg_ in "$@"; do
        python_will_import $arg_ || continue
        quietly $python_ -c "import $arg_; module=$arg_; print(f'{module.__file__}: {module.__version__}')"  || continue
        result_=0
    done
    return $result_
}

make_shebang () {
    sed -e "1s:.*:#! /bin/bash:"
}


ww_bash () {
    local __doc__="""help on bash builtin"""
    is_bash "$@" || return 1
    help "$@"
    return 0
}

ww_function () {
    local __doc__="""whyp a function"""
    quietly is_function "$@"  || return 1
    quietly parse_function_ "$@"
    if [[ $path_to_file != "main" ]]; then
        [[ -f $path_to_file ]] || return 1
    fi
    type $1 | sed -e "/is a function$/d" | wat
    [[ $path_to_file == "main" ]] || echo "$EDITOR $path_to_file +$(( $line_number - 1 )) +/$1"
    return 0
}

ww_alias () {
    is_alias "$@" || return 1
    alias $1
    local tdout_=$(alias $1)
    if [[ $tdout_  =~ is.a.function ]]; then
        name_=$(defended $name_)
        ww_function $name_
    else
        local uffix_=${tdout_//*=\'}
        local command_=${uffix_//\'}
        w $command_
    fi
}

ww_file () {
    is_file "$1" || return 1
    runnable "$1" || return 2

    local path_=$(type "$1" | sed -e "s:.* is ::")
    local text_=1
    quietly file "$path_" | grep -q text || text_=
    if [[ $text_ ]]; then
        local command_=head
        if runnable tldr; then
            command_=tldr
        elif runnable bat; then
            command_=bat
        fi
        $command_ $path_
        echo
    fi
    ls -l $path_
    echo
}

ww_args () {
    local arg_= option_= hifts_=
    for arg_ in "$@"; do
        [[ $arg_ == -v ]] && option_=-v
        [[ $arg_ == verbose ]] && option_=-v
        [[ $arg_ == -q ]] && option_=-q
        [[ $arg_ == quiet ]] && option_=-q
        [[ $arg_ == -vv ]] && option_=-v
        [[ $option_ ]] || continue
        WOPTS=$option_
        echo $arg_
    done
}

whyp_show_ () {
    WOPTS=
    local shower_=quietly args_=$(ww_args "$@") arg_= name_= type_=
    [[ $WOPTS == -v ]] && shower_=
    for arg_ in $args_; do
        name_="$arg_"; shift
        show_="$shower_ $arg_"; shift
        $show_
    done
    return 0
}

ww_show () {
    local ww_= name_= result_=1
    for name_ in "$@"; do
        for ww_ in ww_bash ww_alias ww_function ww_file ; do
            quietly $ww_ $name_ l || continue
            result_=0
        done
    done
    return $result_
}

ww_command () {
    local __doc__="""find what will be executed for a command string"""
    PATH_TO_ALIASES=/tmp/aliases
    PATH_TO_FUNCTIONS=/tmp/functions
    alias > $PATH_TO_ALIASES
    declare -f > $PATH_TO_FUNCTIONS
    ww_py --aliases=$PATH_TO_ALIASES --functions=$PATH_TO_FUNCTIONS "$@";
}

ww_debug () {
    (DEBUGGING=www;
        local command_="$1"; shift
        ww $command_;
        w $command_;
        (set -x; $command_ "$@" 2>&1 )
    )
}

edit_alias_ () {
    local __doc__="""Edit an alias in the file $ALIASES, if that file exists"""
    sources_ --any || return
    local whyp_sources_=$(sources_ --all --optional)
    for sourced_file in $whyp_sources_; do
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

edit_function_ () {
    local __doc__="""Edit a function in a file"""
    local regexp_="^$function[[:space:]]*()[[:space:]]*{[[:space:]]*$"
    if test -f $path_to_file; then
        [[ $path_to_file == "(null)" ]] || return 1
        path_to_file=$WHYP_DIR/edit_functiontmp.sh
        qype "$1" | grep -v "is a function" | sed -e "s/) *$/) {/" -e "/^{ *$/d" > $path_to_file
        line_number=1
    fi
    if ! grep -q $regexp_ "$path_to_file"; then
        printf "$function () {}" >> "$path_to_file"
        return 0
    fi
    local line_=1; [[ -n "$line_number" ]] && line_=+$(( $line_number - 1 ))
    local seek_=+/"^$function "
    [[ "$@" =~ [+][/] ]] && seek_=$(echo "$@" | ses ".*\([+][/][^ ]*\).*" "\1")
    whyp_edit_file "$path_to_file" $line_ $seek_
    test -f "$path_to_file" || return 0
    ls -l "$path_to_file"
    ww_source "$path_to_file"
    [[ $(basename $(dirname "$path_to_file")) == tmp ]] && rm -f "$path_to_file"
    return 0
}

edit_file_ () {
    local __doc__="""Edit a file, it is seems to be text, otherwise tell user why not"""
    local file_=$(ww_py $1)
    [[ -f $file_ ]] || return 1
    if file $file_ | grep -q text; then
        whyp_edit_file  $file_
    else
        echo $file_ is not text >&2
        file $file_ >&2
    fi
}

show_type () {
    local options_=
    [[ $1 == -a ]] && options_=-a && shift
    qype $options_ "$@" || /usr/bin/env | grep --colour "$@"
}

show_file () {
    local options_=; [[ $1 == -a ]] && options_=-a && shift
    qype $options_ "$@"
    echo
    [[ $options_ == -a ]] && qich $options_ "$@"
}

show_function () {
    local options_=; [[ $1 == -a ]] && options_=-a && shift
    parse_function_ $1
    echo "$1 is a function in '$path_to_file':$line_number"
    show_type "$@" | tail -n +2
}

ww_source () {
    local __doc__="""Source optionally"""
    whyp_source "$@" --optional
}

parse_declare_function () {
    local __doc__="""Parse output of declaring a function"""
    function="$1";
    shift;
    line_number="$1";
    shift;
    path_to_file="$*";
}

declare_function () {
    (
        shopt -s extdebug
        declare -F "$1"
    )
}

parse_function_ () {
    parse_declare_function $(declare_function "$1")
}

def_executable () {
    local __doc__="""Hello to the Pythonistas"""
    QUIETLY type $(deafened "$@")
}


old_whyp_type () {
    if is_alias "$1"; then
        type "$1"
    elif is_function "$1"; then
        type "$1"
        echo
        local line_above_=$(( $line_number - 1 ))
        local sought_="'\\<$function\\zs.*'"
        echo "whyp_edit_file $(relpath ""$path_to_file"") +$line_above_ +/$sought"
    elif def_executable "$1"; then
        real_file=$(readlink -f $(which "$1"))
        [[ $real_file != "$1" ]] && echo -n "$1 -> "
        echo "$real_file"
    else type "$1"
    fi
}


# Methods ending with underscores are intended for use in this file only
#   (another convention borrowed from Python)


sources_ () {
    whyp_bin_run sources "$@"
}

write_new_file_ () {
    local __doc__="""Copy the head of this script to file"""
    head -n $eading_lines_ $BASH_SOURCE > "$path_to_file"
}

create_function_ () {
    local __doc__="""Make a new function with a command in shell history"""
    local doc="copied from $(basename $SHELL) history on $(date)"
    local history_command=$(show_history_command_)
    quietly eval "$function() { local __doc__="""$doc"""; $history_command; }"
}

make_path_to_file_exist_ () {
    local __doc__="""make sure the required file exists, either an existing file, a new file, or a temp file"""
    if [[ -f "$path_to_file" ]]; then
        cp "$path_to_file" "$path_to_file~"
        return 0
    fi
    [[ ! "$path_to_file" || $path_to_file == main ]] && path_to_file=$(mktemp /tmp/function.XXXXXX)
    write_new_file_ "$path_to_file"
}

show_history_command_ () {
    local __doc__="""Get a command from the end of current bash history"""
    local line_=
    local words=$(fc -ln -$history_index -$history_index)
    for word in $words
    do
        if [[ ${word:0:1} != "-" ]]; then
            is_alias $word && word="\\$word"
        fi
        [[ -z $line_ ]] && line_=$word || line_="$line_ $word"
    done
    echo $line_
}

source_path () {
    test -f "$1" || return 1
    whyp_source "$@"
}

has_type () {
    [[ "$(qype -t $1 )" =~ $2 ]]
}

# is_xxxx

is_bash () {
    local __doc__="""Whether the first argument is a keyword or builtin"""
    is_types "$1" keyword builtin
}

is_file () {
    local __doc__="""Whether $1 is an executable file"""
    is_hash "$1" && return 0
    local path_=$(qype -P $1 | sed -e "s,.* is ,,")
    [[ $path_ ]] || return 1
    west -x $path_
}

is_hash () {
    is_types "$1" hash
}

is_types () {
    (
        local cmd_=$1
        shift
        local arg_type_= cmd_type_=$(qype -t $cmd_)
        for arg_type_ in "$@"; do
            [[ $cmd_type_ =~ $arg_type_ ]] && return 0
        done
        return 1
    ) 2>/dev/null
}

is_alias () {
    local __doc__="""Whether $1 is an alias"""
    has_type "$1" alias
}

is_function () {
    local __doc__="""Whether $1 is a function"""
    has_type "$1" function
}

is_keyword () {
    local __doc__="""Whether $1 is a keyword"""
    has_type "$1" keyword
}

is_builtin () {
    local __doc__="""Whether $1 is a builtin"""
    has_type "$1" builtin
}

is_unrecognised () {
    local __doc__="""Whether $1 is unrecognised"""
    [[ "$(qype -t $1 )" == "" ]]
}

is_python_module () {
    python_will_import "$@"
}

