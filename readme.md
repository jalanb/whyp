kd
==

what is intended as a replacement for which, to show the source of commands available in bash

The script searches within aliases, functions and files to show the sources. For example, let's imagine you set up an alias to make cd'ing to the parent directory easier, e.g.

	$ alias up='cd ..'

Then the what command can show that up is an alias

$ what up
	alias up='cd ..'

Let's re-write up as a function

	$ unalias up
	$ up ()
	> {
	> cd ..
	> }

Then the what command can show that up is a function

	$ what up
	#! /bin/bash
	up ()
	{
		    cd ..
	}

Installation
------------

For convenience a bash function is also provided, which can be set up like

    $ source what.sh

Then one can use `what` as a replacement for which

