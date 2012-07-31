git branch-notes
================

`git branch-notes` is a Perl program that helps project maintainers
keep a list of notes about all non-remote branches in a Git
repository.  For example, a maintainer can use this program to help
keep track of branches that he needs to merge, or not merge, or
branches that have commits to cherry-pick, et cetera.  This
information remains in the user’s local repository only and is not
shared by `git-push` or other commands, under the assumption that
other project contributors will not need to see maintainer notes.



Installation and Requirements
=============================

To use the program you need to first create a global alias.  You can
do this with `git-config`.  For example, if I have the script at
`/home/eric/Scripts/git-branch-notes.pl` on my computer then I can use
this command to create the alias:

    $ git config --global --add alias.branch-notes "/home/eric/Scripts/git-branch-notes.pl"

Now I can use the command `git branch-notes` in any repository.

The program requires the following software:

1. Perl 5.14 or later.

2. SQLite 3 or later.

3. The Perl module `common::sense`.

4. The Perl module `DBD::SQLite`.

The program may work with older versions of both Perl and SQLite.



Usage
=====

`git branch-notes` has two commands: `show` and `add`.  The first
command will list all of the branches and their notes on standard
output.  The second command will open the user’s editor to add notes
for the current branch.  To determine the editor the program first
looks for the environment variable `EDITOR`, and then checks the Git
configuration value `core.editor`, and failing that aborts with an
error message.



License
=======

This program is Public Domain.
