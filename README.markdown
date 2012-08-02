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

1. `show [branch]`
2. `add [message]`
3. `rm <branch>`
4. `clear`

If the user provides no command then `show` is the default.  Here is
an example of the command, which lists all of the branches and their
notes on standard output:

    $ git branch-notes show
    ejmr/add-command
    ================

    Can I replace notes?



    ejmr/show-command
    =================

    Can almost merge.

The `show` command optionally accepts the name of a branch to display
the notes about only that branch.

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

The `add` command accepts an optional string that the program will
save as the new notes for the current branch.  This will replace the
existing notes if there are any.  For example:

    $ git branch-notes add "Do not merge."

Here is an example of `rm`, which removes notes about a given
branch:

    $ git branch-notes rm ejmr/completed-feature
    Removed notes for ejmr/completed-feature

The `clear` command performs the same action as `rm` except it removes
the notes for *all* branches in the database.



What About git-branch?
======================

There already exists the command `git branch --edit-description` as a
standard part of Git.  So it seems worthwhile to justify the need for
`git branch-notes`.

The most glaring limitation of `git branch --edit-description` is that
it only stores information about one branch at a time.  The
description goes into the file `.git/BRANCH_DESCRIPTION`.  When you
change branches and add a new description that destroys the existing
description file.

The two commands also serve different purposes.  Running `git
request-pull` exposes the information in `.git/BRANCH_DESCRIPTION`.
This helps give the person who may accept the pull a better idea of
the purpose of the branch.  In other words, branch descriptions help
communicate information *to* project maintainers.  The purpose of `git
branch-notes` is for project maintainers to store information for
*themselves* that they do not feel is important to share, i.e. tedious
notes about branch maintenance that would be uninteresting to other
developers on a team.



License
=======

This program is Public Domain.
