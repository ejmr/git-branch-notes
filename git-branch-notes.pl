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
use File::Temp;

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

# Create the table of branch notes information if it does not exist.
# We store two things in each row:
#
#     1. The branch name.
#
#     2. User notes about the branch.
#
# The branch name must be unique.
$database->do(q[
    CREATE TABLE IF NOT EXISTS branch_notes (
        name  TEXT NOT NULL UNIQUE,
        notes TEXT NOT NULL
    );
]);

# Read our command from the command-line.
our $command = $ARGV[0];

# Make sure the command is valid, i.e. one we recognize.
if ($command !~ "show" and $command !~ "add") {
    die("Error: Invalid command $command\n");
}

# Returns an array reference of all of the branch information.  Each
# element in the array is itself an array with two elements:
#
#     1. The name of the branch.
#
#     2. The notes about the branch.
#
# The elements of the array are sorted by branch name in ascending
# alphabetical order.
sub get_branch_information() {
    return $database->selectall_arrayref(q[
        SELECT name, notes
        FROM branch_notes
        ORDER BY name ASC;
    ]);
}

# Returns the name of the editor to use for adding new notes.  If we
# cannot find a suitable editor then this function will return an
# empty string.
sub get_editor() {
    if ($ENV{"EDITOR"}) {
        return $ENV{"EDITOR"};
    }
    elsif (qx(git config --get core.editor)) {
        return qx(git config --get.core.editor);
    }
    else {
        return q();
    }
}

# Process the 'show' command.  We display the name and notes for each
# branch on standard output.  The output format is in Markdown and
# uses multiple newlines to separate branches.  That is because
# personally I intended to often redirect the output of this command
# into emails, and those I always write in Markdown.
if ($command ~~ "show") {
    my $information = get_branch_information;

    for my $branch (@$information) {
        say $branch->[0];
        say "=" x length($branch->[0]), "\n";
        say $branch->[1], "\n\n\n";
    }
}

# Process the 'add' command.  This opens up the user's editor and
# reads in a note to save for the current branch.
if ($command ~~ "add") {
    my $current_branch = qx(git name-rev --name-only HEAD);
    strip_newlines_from $current_branch;

    # We store the notes in a temporary file.
    my $notes_file = File::Temp->new();
    my $editor = get_editor;

    say "Waiting on $editor...";
    qx($editor $notes_file);

    # Now read the entire contents of $notes_file into the scalar
    # $notes as a single string.  To do this we temporarily undefine
    # the special $/ variable so that the <> operator will read in
    # everything at once.  See 'perldoc perlfaq5' for information on
    # this trick.
    my $notes;
    {
        local $/ = undef;
        open my $temporary_file_handle, "<", $notes_file
            or die("Error: Cannot read from notes file $notes_file\n");
        $notes = <$temporary_file_handle>;
    }

    say "\n$current_branch\n\n$notes";
}

__END__
