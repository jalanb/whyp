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

[[ -d ~/whyp/ ]] && . ~/whyp/whyp/exports.sh

# x

# https://www.reddit.com/r/commandline/comments/2kq8oa/the_most_productive_function_i_have_written/
e () {
    local __doc__="""Edit the first argument as if it's a type, pass on $@ to editor"""
    is_bash "$1" && return
    is_file "$1" && edit_file_ "$@" && return $?
    if is_function "$1"; then
        parse_function_ "$1"
        edit_function_ "$@"
        return 0
    fi
    if is_alias "$1"; then
        edit_alias_ "$1"
        return 0
    fi
    local file_= sought_= "$1"; shift
    python_will_import "$1" && file_=$(python_module "$1") || file_="$1"; shift
    whyp_edit_file "$file_" +/"$sought_" "$@"_
}

alias .=whyp_source
alias w=whyp

# xx

alias .w=source_whyp_source
alias wa="whyp --all"
alias wq="quietly whyp "

ww () {
    local __doc__="""ww expands type"""
    [[ "$@" ]] || return 1
    local hyp_options_=$(ww_option "$@")
    [[ $hyp_options_ ]] && shift
    local name_="$1"; shift
    ww_show "$name_"
    [[ $? == 0 ]] && return 0
}

alias .w="whyp_source $WHYP_SOURCE"

# xxx

ses () {
    if [[ $1 == -e ]]; then
        sed "$@"
    else
        sed -e "s,$1,$2",
    fi
}

wat () {
    local md_=cat
    is_file kat && md_=kat
    is_file bat && md_=bat
    $md_ "$@"
}
# xxxx

whyp () {
    local __doc__="""whyp extends type"""
    [[ "$@" ]] || echo "Usage: w <command>"
    # -a, --all
    local lls_regexp_="--*[al]*" options_=
    [[ "$1" =~ $lls_regexp_ ]] && options_=--all
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

ww_help () {
    local unction_=$1; shift
    rm -f /tmp/err
    [[ $1 =~ (-h|--help) ]] && ww $unction_ 2>/tmp/err
    local result_=$?
    [[ -f /tmp/err ]] && return 2
    return $result_
}

de_alias () {
    sed -e "/is aliased to \`/s:.$::" -e "s:.* is aliased to [\`]*::"
}

de_file () {
    sed -e "s:[^ ]* is ::"
}

de_hashed () {
    local ommand_=$1
    local ype_="$@"
    if [[ $ype_ =~ hashed ]]; then
        local ehash_=$(echo $ype_ | sed -e "s:.*hashed (\([^)]*\)):\1:")
        ype_="$ommand_ is $ehash_"
    fi
    echo $ype_
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

whyp_source () {
    local __doc__="""Source a file (that may set some aliases) and remember that file"""
    local filename_=$(readlink -f "$1") expected=1
    [[ $2 == "optional" ]] && expected=
    if [[ -f $filename_ ]]; then
      source $filename_
      return 1
    elif [[ $expected ]]; then
        echo Cannot source \"$filename_\". It is not a file. >&2
    fi
}

ww_executable () {
    QUIETLY type $(deafened "$@")
}

# xxxxx

source_whyp_source () {
    . $WHYP.sh
}

# xxxxx*

ww_bin () {
    local __doc__="""Full path to a script in whyp/bin"""
    echo $WHYP_BIN/"$1"
}

whyp_bin_run () {
    local __doc__="""Run a script in whyp/bin"""
    local cript_=$(ww_bin $1); shift
    if [[ -d $WHYP_VENV ]]; then
        (
            source "$WHYP_VENV/bin/activate"
            PYTHONPATH=$WHYP_DIR $cript_ "$@"
        )
    else
        PYTHONPATH=$WHYP_DIR $cript_ "$@"
    fi
}

whyp_pudb_run () {
    local __doc__="""Debug a script in whyp/bin"""
    local cript_=$(ww_bin $1); shift
    set -x
    PYTHONPATH=$WHYP_DIR pudb $cript_ "$@"
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
    local file_=$1; shift
    [[ -f $file_ ]] || return 1
    local dir_=$(dirname $file_)
    [[ -d $dir_ ]] || dir_=.
    local name_=$(basename $file_)
    local editor_=$WHYPED
    [[ $EDITOR ]] && editor_=$EDITOR
    (cd $dir_; $editor_ $name_ "$@")
}

python_has_debugger () {
    [[ $1 =~ ^((3(.[7-9])?)|([4-9](.[0-9])?))$ ]]
}

looks_versiony () {
    [[ ! $1 ]] && return 1
    [[ $1 =~ [0-9](.[0-9])* ]]
}

local_python () {
    local ocal_python_name_=python
    if looks_versiony $1; then
        if python_has_debugger $1; then
            ocal_python_name_=python$1
        else
            ocal_python_name_=python2
            echo "Requested python version too old" >&2
        fi
        shift
    else
        ocal_python_name_=python3
    fi
    local ocal_python_=$(PATH=/usr/local/bin:/usr/bin/:/bin which $ocal_python_name_ 2>/dev/null)
    [[ $ocal_python_ ]] && $ocal_python_ -c "import sys; sys.stdout.write(sys.executable)"
}

ww_option () {
    local options_=
    [[ $1 == -q ]] && options_=quiet
    [[ $1 == -v ]] && options_=verbose
    [[ $1 == verbose ]] && options_=verbose
    [[ $1 == quiet ]] && options_=quiet
    [[ $1 == -f ]] && options_="$ptions_ --is-function"
    [[ $1 == -a ]] && options_="$ptions_ --is-alias"
    [[ $options_ ]] || return 1
    echo $options_
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
    local result_=1
    for arg in "$@"; do
        looks_like_python_name $arg || continue
        python -c "import $arg; print($arg.__file__)" 2>/dev/null || continue
        result_=0
    done
    return $result_
}

python_module_version () {
    local __doc__="""the installed version of that python package"""
    local result_=1 arg_=
    for arg_ in "$@"; do
        python_will_import $arg_ || continue
        python -c "import $arg_; module=$arg_; print(f'{module.__file__}: {module.__version__}')" 2>/dev/null || continue
        result_=0
    done
    return $result_
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
    local ines_=
    if [[ $1 =~ ^[0-9]+$ ]]; then
        ines_=$1
        shift
    fi
    if runnable bat; then
        bat --language=bash --style=changes,grid,numbers "$@"
    elif runnable kat; then
        kat --numbers "$@"
    elif [[ $ines_ > 40 ]]; then
        less "$@"
    else
        cat "$@"
    fi
    [[ $1 ]] || return 0
    ines_=$(wc -l "$1" | sed -e "s, .*,," 2>/dev/null)
    [[ $ines_ == 0 ]] || return 0
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
    parse_function_ "$@"
    [[ -f $path_to_file ]] || return 1
    type $1 | sed -e "/is a function$/d" | wat
    echo "'$path_to_file:$line_number' $function ()"
    echo "$EDITOR $path_to_file +$line_number"
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
        local ommand_=${uffix_//\'}
        w $ommand_
    fi
}

ww_file () {
    is_file "$@" || return 1
    local ath_=$(type "$1" | sed -e "s:.* is ::")
    local ommand_=less
    runnable bat && ommand_=bat
    $ommand_ $ath_
    ls -l $ath_
    return $ass_
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
    local shower_=quietly rgs_=$(ww_args "$@") arg_= name_= ype_=
    [[ $WOPTS == -v ]] && shower_=
    for arg_ in $rgs_; do
        name_="$arg_"; shift
        ype_="$shower_ $arg_"; shift
        $ype_
    done
    return 0
}

ww_show () {
    local whyp_= name_="$1"
    shift
    for whyp_ in ww_bash ww_function ww_alias ww_file ; do
        whyp_show_ $name_ $whyp_ || continue
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
        local ommand_="$1"; shift
        ww $ommand_;
        w $ommand_;
        (set -x; $ommand_ "$@" 2>&1 )
    )
}

edit_alias_ () {
    local __doc__="""Edit an alias in the file $ALIASES, if that file exists"""
    sources_ --any || return
    local hyp_sources_=$(sources_ --all --optional)
    for sourced_file in $hyp_sources_; do
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
    local ade_=
    make_path_to_file_exist_ && ade_=1
    local egexp_="^$function[[:space:]]*()[[:space:]]*{[[:space:]]*$"
    local ew_=
    if ! grep -q $egexp_ "$path_to_file"; then
        line_number=$(wc -l "$path_to_file")
        echo "Add $function onto $path_to_file at new line $line_number"
        set +x; return 0
    fi
    local line_=; [[ -n "$line_number" ]] && line_=+$line_number
    local eek_=+/$egexp_
    [[ "$@" =~ [+][/] ]] && eek_=$(echo "$@" | ses ".*\([+][/][^ ]*\).*" "\1")
    whyp_edit_file "$path_to_file" $line_ $eek_
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
    type $options_ "$@" 2>/dev/null || /usr/bin/env | grep --colour "$@"
}

show_file () {
    local options_=; [[ $1 == -a ]] && options_=-a && shift
    type $options_ "$@"
    echo
    [[ $options_ == -a ]] && which $options_ "$@" 2>/dev/null
}

show_function () {
    local options_=; [[ $1 == -a ]] && options_=-a && shift
    parse_function_ $1
    echo "$1 is a function in '$path_to_file':$line_number"
    show_type "$@" | tail -n +2
}

ww_source () {
    local __doc__="""Source optionally"""
    whyp_source "$@" optional
}


quietly unalias .


# xxxx_+

www_ () {
    ww verbose "$@"
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
    local __doc__="""Declare name, line and path of a function"""
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
    [[ "$(type -t $1 2>/dev/null)" =~ $2 ]]
}

is_alias () {
    local __doc__="""Whether $1 is an alias"""
    has_type "$1" alias
}

is_function () {
    local __doc__="""Whether $1 is a function"""
    has_type "$1" function
}

is_bash () {
    local __doc__="""Whether the first argument is a keyword or builtin"""
    is_keyword $1 || is_builtin $1
}

is_keyword () {
    local __doc__="""Whether $1 is a keyword"""
    has_type "$1" keyword
}

is_builtin () {
    local __doc__="""Whether $1 is a builtin"""
    has_type "$1" builtin
}

is_file () {
    local __doc__="""Whether $1 is an executable file"""
    has_type "$1" hash && return 0
    local path_=$(type -t $1 2>dev/null | sed -e "s,.* is ,,")
    test -f $path_
}

is_unrecognised () {
    local __doc__="""Whether $1 is unrecognised"""
    [[ "$(type -t $1 2>/dev/null)" == "" ]]
}
