#!/usr/bin/env perl
#
# git branch-notes [show|add]
#
# This script provides a Git command that keeps a database of notes on
# all non-remote branches.  The intent is to help project maintainers
# keep track of details on branches, such as which ones to merge,
# particular commits to cherry-pick, and so on.  See the file
# 'README.markdown' for more information about how to use the program.
#
#
#
# Author: Eric James Michael Ritz
#         lobbyjones@gmail.com
#         https://github.com/ejmr/git-branch-notes
#
# License: This code is Public Domain.
#
######################################################################

use common::sense;
use DBI;

# Removes all newlines from the given string.  This seems redundant
# because of chomp() but when parsing the output of Git commands we
# can end up with newlines in the middle of strings.  So we use this
# function since chomp() will not remove those.
sub strip_newlines_from(_) { s/\n//g for $_[0]; }

# We store the notes in an SQLite database inside of the '.git/info'
# directory at the top-level of a repository.  However, since the
# program may be run in a sub-directory we need to call git-rev-parse
# to find out just where the top-level is.
our $git_info_directory = qx(git rev-parse --show-toplevel) . "/.git/info";

# We have a newline in the middle of our info directory to get rid of.
strip_newlines_from $git_info_directory;

# The name of our database file.
our $database_filename = "$git_info_directory/branch-notes.sqlite";

# Open the database or abort.
our $database = DBI->connect("dbi:SQLite:dbname=$database_filename")
    or die("Error: Could not open $database_filename\n");

# Exit immediately if we have any database errors.
$database->{RaiseError} = 1;

__END__
