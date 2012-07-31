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

__END__
