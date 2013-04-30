#! /bin/bash

# This script is intended to be sourced, not run
if [[ $0 == $BASH_SOURCE ]]
then
    echo "This file should be run as"
    echo "  source $0"
    echo "and should not be run as"
    echo "  sh $0"
fi
#
_license="This script is released under the MIT license, see http://jalanb.mit-license.org/"
#
_heading_lines=13 # Text before here is copied to new files

what ()
{
	local __doc__="find what will be executed for a command string"
	PATH_TO_ALIASES=/tmp/aliases
	PATH_TO_FUNCTIONS=/tmp/functions
	alias > $PATH_TO_ALIASES
	declare -f > $PATH_TO_FUNCTIONS
	python $JAB/python/what/what.py --aliases=$PATH_TO_ALIASES --functions=$PATH_TO_FUNCTIONS $*;
	local return_value=$?
	rm -f $PATH_TO_ALIASES
	rm -f $PATH_TO_FUNCTIONS
	return $return_value
}

vw ()
{
	local __doc__="Edit the first argument if it is a text file"
	if [[ $(type -t $1) == "file" ]]
	then
		local file=$(type -p $1)
		if file $file | grep -q text
		then $EDITOR $file
		else echo $file is not text
		fi
	else type $1
	fi
}

wv ()
{
	local __doc__="run what verbosely on all the arguments"
	what -v "$*"
}

whap ()
{
	local __doc__="find what python will import for a string"
	local executable=python
	if [[ $1 =~ [23].[0-9] ]]
	then
		executable=python$1
		shift
	fi
	$executable $JAB/python/what/whap.py $*
}

whet ()
{
	local __doc__="whet makes it easier to name a command, then re-edit it"
	local function=
	local history_index=1
	local path_to_file=
	_read_whet_args $* || return $?
	if [[ -z $function ]]
	then
		unset fred
		function=fred
	fi
	if _existing_function $function
	then
		_edit_function
	else
		_create_function
	fi
}
		
# Methods starting with underscores are intended for use in this file only
#	(a convention borrowed from python)

_read_whet_args ()
{
	local __doc__="evalute the args to the whet function by type, not position"
	for arg in $*
	do
		if _is_script_name $arg
		then local path_to_file=$arg
		elif _is_number $arg
		then history_index=$arg
		elif _is_identifier $arg
		then
			_existing_command $arg && return 1
			function=$arg
		fi
	done
}

_create_function ()
{
	local __doc__="Make a new function with a command in shell history"
	local doc="copied from $(basename $SHELL) history on $(date)"
	local history_command=$(_show_history_command)
	eval "$function() { local __doc__='$doc'; $history_command; }" 2>/dev/null
}

_write_new_file ()
{
	local __doc__="Copy the head of this script to file"
	head -n $heading_lines $BASH_SOURCE > $path_to_file
}

_make_path_to_file_exist ()
{
	local __doc__="make sure the required file exists, either an existing file, a new file, or a temp file"
	if [[ -n $path_to_file ]]
	then
		if [[ -f $path_to_file ]]
		then
			cp $path_to_file $path_to_file~
		else
			_write_new_file $path_to_file
		fi
	else
		path_to_file=$(mktemp /tmp/function.XXXXXX)
	fi
}

_edit_function ()
{
	local __doc__="Edit a function in a file"
	_make_path_to_file_exist
	local regexp="^$function[[:space:]]*()[[:space:]]*$"
	if ! grep -q $regexp $path_to_file
	then declare -f $function >> $path_to_file
	fi
	$EDITOR $path_to_file +/$regexp
	source $path_to_file
	[[ $(dirname $path_to_file) == /tmp ]] && rm -f $path_to_file
}

_existing_function ()
{
	local __doc__="Whether the first argument is in use as a function"
	[[ "$(type -t $1)" == "function" ]]
}

_existing_alias ()
{
	local __doc__="Whether the first argument is in use as a alias"
	[[ "$(type -t $1)" == "alias" ]]
}

_existing_command ()
{
	local __doc__="Whether the name is in use as an alias, executable, ..."
	if _existing_function $1
	then return 1
	else type $1 2>/dev/null
	fi
}

_show_history_command ()
{
	local __doc__="Get a command from the end of current bash history"
	local line=
	local words=$(fc -ln -$history_index -$history_index)
	for word in $words
	do
		if [[ ${word:0:1} != "-" ]]
		then _existing_alias $word && word="\\$word"
		fi
		[[ -z $line ]] && line=$word || line="$line $word" 
	done
	echo $line
}

_is_script_name ()
{
	local __doc__="Whether the first argument ends in .sh, or is a file"
	[[ "$1" =~ \.sh$ || -f $1 ]]
}

_is_number ()
{
	local __doc__="Whether the first argument has only digits"
	[[ "$1" =~ ^[0-9]+$ ]]
}

_is_identifier ()
{
	local __doc__="Whether the first argument is alphanumeric and underscores"
	[[ "$1" =~ ^[[:alnum:]_]+$ ]]
}
