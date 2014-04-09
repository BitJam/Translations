Translation automation for antiX
================================

**Note:** YOU MUST use the tx client to create a translations/ subdirectory
(or make a symlink named translations to that subdirectory).
We look for all the .po files under that subdirectory.


Introduction
------------
This bundle automates many of the translation tasks for antiX and
similar distros.  We hope to expand its functionality to handle
similar tasks.  For now it generates .mo files from .po files and
creates .xlat files and modified scripts used by our xlat
translation system.

It is based on getting translations done on the web site
https://www.transifex.com/.  It assumes you are uploading and
downloading files via the "tx" client program.  The translations
are assumed to be under the translations/ subdirectory which can
be (and pehaps should be) be a symlink.  You also need the
 .tx/config file to use the "tx" program.  This can probably be
easily adapted to work with other systems.  All that is required
is a rational directory structure containing all the .po files
that will be used.  For now, at least, you will need to run the
"tx" script manually.

The .po files containing translations are used in at least two
different systems.  One system simple creates .mo files that will
end up on the target system under /usr/share/locale.  These are
created with "make mo".

The other system creates .xlat files for the /init script and the
Live init.d/ scripts.  It also makes modified copies of the
scripts. substituting English strings for variables that are
defined in the .xlat files.  under the /usr/share/antiX/init-xlat
directory.

Use Makefile.local for customization
------------------------------------
The two things I use it for are DOMAINS_FILE which controls
which `.mo` files we make and INITRD_IDIR which controls where the
initrd files get copied to:

    INITRD_IDIR   := ../LiveUSB/14-alpha-2/initrd
    DOMAINS_FILE  := ANTIX_NAMES

If you want the .mo files installed somewhere out of this directory tree
then you should also define PREFIX in this file.  This approach will let
you accept updates to the `Makefile` without losing your changes in
`Makefile.local`.


Inputs for Making .mo Files
---------------------------
Standard translations are controled by 2 input files:

<dl>

  <dt>TEXT_DOMAINS</dt>
  <dd>Names of programs that get .mo files</dd>

  <dt>TEXT_RENAME</dt>
  <dd>Program names that have changed</dd>
</dl>

Although now `ANTIX_NAMES` and `MX_NAMES` contain the
list of program names that get `.mo` files.

The renaming is needed because the names of some programs have
changed while the names used by the website have not.  

Inputs for making .xlat Files
-----------------------------

The Xlat system only works with shell scripts.  It must modify
the source code to replace a class of literal strings with
variables.  The .xlat files contain source code that assigns
values to these variables.  For each program there must but a
 .xlat file for each language the program has been translated
into.  Unlike the standard .mo system, we NEED to have an en.xlat
file or else all the strings that are supposed to be translated
will be empty.  On the plus side, this is much faster than
calling gettext for every string and it works on systems where
gettext is not available, in particular inside the initrd.


.mo File Outputs
----------------

These are standard .mo files and are placee under
Output/usr/share/locale/ in the standard places

.xlat File Outputs
------------------

Some of the outputs end up under the Output/ directory and
others end up under the Initrd/ directory.  This is controlled
by whether the source files are under Src/sqfs/ or
Src/live-initrd/

Xlat Files are small scripts that assign values to variables.
Here are some examples:

```=Shell
_Setting_language_via_X_="Setting language via %s"

_Unknown_language_code_X_="Unknown language code %s"

_Valid_languages_codes_X_="Valid languages codes %s"
```

In addition to the modified scripts and xlat files that are put
in the $PREFIX directory tree, .pot files are put in the local
pot-files/ directory.  These should be used to create .mo files
that get put under $TEXTDOMAINDIR.  Note that files under
$TEXTDOMAINDIR are used strictly as inputs.  Nothing gets
automatically written there.


Scripts
-------

Scripts reside under the Scripts/ directory.

<dl>

  <dt>replace-strings</dt>

  <dd>Main tool to make .xlat files.  This tool will replace
  English strings in a script with variable names.  It will also
  create a script that defines those variable to be the English
  string values.  And finally it can write a *stringmaker* script
  that writes a script to define the variables which is how we do
  the translation </dd>

  <dt>make-xlat-files</dt>

  <dd>The next level up from `replace-strings`.  This
  script calls replace-strings and the get gettext utilities
  `xgettext` and `msgfmt` to create the .xlat and .mo files
  needed for translation.  Often I call this script directly
  instead of calling it via the Makefile.</dd>


  <dt>validate-xlat</dt>
  <dd>Validate .xlat files.  Since the .xlat files are executed,
  it is possible for there to be unwanted code execution, for
  example *"Say Hello $(rm -rf /)!"*.  If there are hidden bombs
  in a .xlat file, this script will find the first. It cannot
  be run as root.  It also makes sure *no* interpolation happens
  in the strings in the .xlat files.</dd>

    <dt>compare-dirs</dt>
    <dd>A simple tool to compare all the files under two
    different directories.  Used to compare old and new
    .mo and .xlat files.  Very useful but still a work in
    progress.</dd>

</dl>

Make Targets
-------------

The top level of abstraction above make-xlat-files is the
Makefile.  Much of the original functionality of the Makefile was
transferred to make-xlat-files because it was getting cumbersome
to allow the Makefile deal with a a varying number of .po files.
It is possible in a Makefile but it was cleaner and more flexible
to move some Makefile functionality into the make-xlat-files
shell script.  I will often intermix calling make and calling
make-xlat-files directly.

<dl>

  <dt>all</dt>
  <dd>Create all output scripts,  .xlat files, and .mo
  files</dd>

  <dt>xlat</dt>
    <dd>Create all output scripts and .xlat files.</dd>

  <dt>mo</dt>
  <dd>Create all output .mo files.  These will end up
    under $DISTRO/usr/share/locale</dd>

  <dt>validate</dt>
  <dd>Validate all .xlat files that have been created.</dd>

  <dt>clean</dt>
  <dd> Delete all output and intermediate files and
  directories</dd>

  <dt>force-all<dt>
  <dd>Force all outputs to be created from scatch.  No dependency
  checking.  This is like -B for normal Makefiles</dd>

  <dt>force-xlat</dt>
  <dd>Force output scripts and .xlat files to be created.</dd>

  <dt>force-mo</dt>
  <dd>Force all output .mo files to be created.</dd>

  <dt>initrd</dt>
  <dd>Force /init script and init.xlat to be created.</dd>

  <dt>install-initrd</dt>
  <dd>Copy Initrd/ directory to INITRD_IDIR directory.</dd>

  <dt>install<dt>
  <dd>Copy all files under Output/ to the / file system.  Change
  the location it is copied with the PREFIX variable.  </dd>

  <dt>uninstall</dt>
  <dd>Delete all files and directories that were copied with a
  "make install".  It uses the file under Output/ to determine
  what to delete.  Maybe be unsafe.</dd>

</dl>

Directories
-----------

    Input:
    ------
    Src/             Source code for scripts to be xlated.
    Scripts/         Scripts that run the show
    translations/    All .po files

    Output:
    -------
    Output/          What goes into a squashfs file
    Initrd/          What goes into an initrd

    Intermediate:
    -------------
    pot-files/
    string-maker/
    mo-files/


Counting files (as of Sat March 8, 2014)
----------------------------------------
  955 .po files on transifex all
  638 .po files on transifex non-empty

  522 .mo files in /usr/share/locale
   79 .mo files in mo-files
  601 .mo files total

Okay.  There are 37 .po files that aren't used.
