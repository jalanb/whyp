what
====

what is intended as a replacement for which, to show the source of commands available in bash

Installation
------------

For convenience a bash function is provided, which can be set up like

    $ source what.sh

Then one can use `what` as a replacement for which

Use
---

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

Testing
-------

Running the command without any command will test it

	$ what

The author has tested the script
* on OSX using python 2.5, 2.6 and 2.7 and bash 3.2.48
* on CentOS using python 2.4 and 2.7 and bash 3.2.25
* on Ubuntu 10.04 using python 2.7 and bash

