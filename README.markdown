git branch-notes
================

`git branch-notes` is a Perl program that helps project maintainers
keep a list of notes about all branches in a Git repository.  For
example, a maintainer can use this program to help keep track of
branches that he needs to merge, or not merge, or branches that have
commits to cherry-pick, et cetera.  This information remains in the
user’s local repository only and is not shared by `git-push` or other
commands, under the assumption that other project contributors will
not need to see maintainer notes.



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

`git branch-notes` accepts the following commands:

1. `show`
2. `add`
3. `rm <branch>`
4. `clear`

Here is an example of the `show` command, which lists all of the
branches and their notes on standard output:

    $ git branch-notes show
    ejmr/add-command
    ================

    Can I replace notes?



    ejmr/show-command
    =================

    Can almost merge.

Here is an example of `add`, which saves notes about the current
branch:

    $ git branch-notes add
    Waiting on emacs...
    Saved notes for ejmr/rm-notes

During the ‘Waiting on…’ statement the program opens the user’s editor
on a temporary file where the user writes the notes he wants to save.
Any existing notes for the current branch will be available for
editing.  To determine the editor the program first looks for the
environment variable `EDITOR`, and then checks the Git configuration
value `core.editor`, and failing that aborts with an error message.

Here is an example of `rm`, which removes notes about a given
branch:

    $ git branch-notes rm ejmr/completed-feature
    Removed notes for ejmr/completed-feature

The `clear` command performs the same action as `rm` except it removes
the notes for *all* branches in the database.



License
=======

This program is Public Domain.
