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

Let's re-write up as a function

	$ unalias up
	$ up ()
	> {
	> cd ..
	> }

Then the what command can show that up is a function.

	$ what up
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

If you add the verbose flag ('-v') the contents of that file are shown too

	$ what -v up
	-rwxr-xr-x 1 jalanb staff 19 Apr 24 22:56 /home/jalanb/bin/up
	#! /bin/bash
	cd ..

whap
----

The `whap` command tries to find where python will import files from, for example

	$ whap os
	-rw-r--r-- 1 root root 24258 Sep 19  2006 /usr/lib/python2.4/os.py

Note that the whap command uses whatever the default installation of python is, hence in the example above it found the module used for the python2.4 installation. The python file can also be used directly to find where imports are from for other python installations

	$ python2.7 whap.py os
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
