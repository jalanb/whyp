what
====

what is intended as a replacement for which, to show the source of commands available in bash
whap is intended as an equivalent command for python, to show whence modules and packages are imported

Installation
------------

For convenience a bash function is provided, which can be set up like

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
	declare -f up

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

And the what command would then find the file, and show a long ls for it

	$ what up
	-rwxr-xr-x 1 jalanb staff 19 Apr 24 22:56 /home/jalanb/bin/up

If you add the verbose flag, -v, then the source of that file is shown too

	$ what -v up
	-rwxr-xr-x 1 jalanb staff 19 Apr 24 22:56 /home/jalanb/bin/up
	#! /bin/bash
	cd ..

If you add the quiet flag, -q, then no output is shown, which can be useful when using what in scripts

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

Note that the whap command uses whatever the default installation of python is, hence in the example above it found the module used for the python2.4 installation. The python version can also be used specified as an argument to find imports for other python installations. Such a version argument must be the first argument.

	$ whap 2.7 os
	-rw-r--r-- 1 root root 26300 Aug 12  2012 /usr/local/lib/python2.7/os.py

Testing
-------

Running a command without any arguments will test it

	$ what
	$ whap

The author has tested the scripts
* on OSX 10.7 using python 2.5, 2.6 and 2.7 with bash 3.2.48
* on CentOS 5.0 using python 2.4 and 2.7 with bash 3.2.25
* on Ubuntu 10.04 using python 2.6 and 2.7 with bash 4.1.5
