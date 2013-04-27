what
====

what is intended as a replacement for which, to show the source of commands available in bash
whap is intended as an equivalent command for python, to show whence modules and packages are imported
whet makes it easier to name a command from the bash history, then re-edit it

Installation
------------

For convenience bash functions are provided, which can be set up like

    $ source what.sh

Then one can use `what` as a replacement for which, or `whap` to find whence python imports

what
----

what searches within aliases, functions and files to show the sources. For example, let's imagine you set up an alias to make cd'ing to the parent directory easier, e.g.

	$ alias up='cd ..'

Then the what command can show that up is an alias

	$ what up
	alias up='cd ..'

If you add the verbose flag, -v, then it will look "into the alias" and run what on that command too. In this example "cd" turns out to be a file, so that is shown too

	$ what up -v
	alias up='cd ..'
	-r-xr-xr-x 15 root wheel 190 Mar 25 18:03 /usr/bin/cd

	#!/bin/sh
	# $FreeBSD: src/usr.bin/alias/generic.sh,v 1.2 2005/10/24 22:32:19 cperciva Exp $
	# This file is in the public domain.
	builtin `echo ${0##*/} | tr \[:upper:] \[:lower:]` ${1+"$@"}

Let's re-write up as a function

	$ unalias up
	$ up ()
	> {
	> cd ..
	> }

Then the what command can show that up is a function.

	$ what up
	up is a function

If you add the verbose flag, -v, then the source of the function is shown

	$ what up -v
	#! /bin/bash
	up ()
	{
		    cd ..
	}

The up command could also be written as a file

	$ unset up
	$ echo "#! /bin/bash" > ~/bin/up
	$ echo "cd .." >> ~/bin/up
	$ chmod +x ~/bin/up

And the what command would then find the file, and show a long `ls` for it

	$ what up
	-rwxr-xr-x 1 jalanb staff 19 Apr 24 22:56 /home/jalanb/bin/up

If you add the verbose flag, -v, then the source of that file is shown too

	$ what -v up
	-rwxr-xr-x 1 jalanb staff 19 Apr 24 22:56 /home/jalanb/bin/up
	#! /bin/bash
	cd ..

If you add the quiet flag, -q, then no output is shown, which can be useful when using `what` in scripts

	$ if what -q ls; then echo yes; else echo no; fi
	yes

If you add the errors flag ('-e') then the script will hide some errors shown in bash commands.

	Some bash commands can show errors, but give a successful return code.
	With '-e' the script runs, and hides these error messages.
	Without '-e' the script fails and shows the error (this is default)

whap
----

The `whap` command tries to find where python will import files from, for example

	$ whap os
	-rw-r--r-- 1 root root 24258 Sep 19  2006 /usr/lib/python2.4/os.py

Note that the whap command uses whatever the default installation of python is, hence in the example above it found the module used for the python2.4 installation. The python version can also be specified as an argument to find imports for other python installations. Such a version argument must be the first argument.

	$ whap 2.7 os
	-rw-r--r-- 1 root root 26300 Aug 12  2012 /usr/local/lib/python2.7/os.py

whet
----

The English meaning of "whet" is "to sharpen, as by grinding or friction, to hone", and the `whet` command assists this for bash commands by making it easier to copy commands from your history into a function, then re-edit it until you are happy with it, then save it to a file.
	
What it does in particular depends on the number of arguments, which would usually increase on each call.

The command on its own puts the last line from bash history into a function called fred (It was from [Dr Mike Scott](http://www.computing.dcu.ie/~mike/mike.html) that I first heard "If in doubt, call it Fred".)

	$ ls not.a.real.file
	ls: not.a.real.file: No such file or directory
	$ whet
	$ type fred
	fred is a function
	fred ()
	{
		ls not.a.real.file
	}

And that function replays the last command (the `ls` in the example)

	$ fred
	ls: not.a.real.file: No such file or directory
	
You can pass a number of parameters, which `whet` will interpret sensibly. A number can be used to take a different command from the history, so this example will take the 7th last command

	$ whet 7

A name can be used for the function replace the default "fred". For example we could create a function called stuff from the last command

	$ whet stuff
	$ type stuff
	stuff is a function
	stuff ()
	{
		whet 7
	}

If you use a name of an existing function then that function will be editted (using the editor specified by $EDITOR). When the editor exits that script is re-sourced, so any changes are loaded back into bash.

And you can also supply a filename, so that any edits happen in that file, e.g.

	$ whet stuff script.sh

Again - if that script already exists it will be re-used.

So the normal usage of whet is to run a command at the bash prompt until it is getting too big to edit easily using just "<up><left><left><left>...", then run the function, edit it with whet, re-run the function, re-edit, until it is good enough, and save it to a file, for example

	$ ls
	$ ls ../../../
	$ whet 
	$ fred
	$ whet fred
	$ fred
	$ whet fred
	$ fred
	$ whet fred my_ls.sh

Testing
-------

Running commands without any arguments will test them

	$ what
	$ whap

The author has tested the scripts
* on OSX 10.7 using python 2.5, 2.6 and 2.7 with bash 3.2.48
* on CentOS 5.0 using python 2.4 and 2.7 with bash 3.2.25
* on Ubuntu 10.04 using python 2.6 and 2.7 with bash 4.1.5
