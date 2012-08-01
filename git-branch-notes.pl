#!/usr/bin/env perl
#
# git branch-notes [show [branch] | add [message] | rm <branch> | clear]
#
# This script provides a Git command that keeps a database of notes on
# branches.  The intent is to help project maintainers keep track of
# details on branches, such as which ones to merge, particular commits
# to cherry-pick, and so on.  See the file 'README.markdown' for more
# information about how to use the program.
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

our $VERSION = "1.0";

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

# Read our command from the command-line.  If there is no given
# command then we default to 'show'.
our $command = $ARGV[0] || "show";

# These are valid commands.
our @valid_commands = qw(show add rm clear);

# Make sure the command is valid, i.e. one we recognize.
unless (grep { $command ~~ $_ } @valid_commands) {
    die("Error: Invalid command $command\n");
}

# Some commands take an extra argument.  Here we read it if it exists.
# But if there isn't one then we set the argument to an empty string.
our $argument = q();

if ($#ARGV > 0) {
    $argument = $ARGV[1];
}

# If a command requires $argument to have a value, i.e. a non-empty
# string, we test for that here and report an error if there is no
# argument to use.
our @commands_requiring_argument = qw(rm);

if (grep { $command ~~ $_ } @commands_requiring_argument) {
    unless ($argument) {
        die("Error: Command $command requires an argument\n");
    }
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

# Takes a branch name and a string of notes, and saves those notes in
# the database for that branch.  If the branch is already in the
# database then the new notes replace the existing ones.  This
# function returns no value.
sub save_notes_for_branch($$) {
    my ($branch, $notes) = @_;
    my $insert = $database->prepare(q[
        INSERT OR REPLACE INTO branch_notes (name, notes) VALUES (?, ?);
    ]);

    $insert->execute($branch, $notes);
}

# Removes the information about the given branch from the database.
# This function returns no value.
sub remove_branch($) {
    my ($branch) = @_;
    my $delete = $database->prepare(q[
        DELETE FROM branch_notes WHERE name = ?;
    ]);

    $delete->execute($branch);
}

# Removes information about all branches from the database.  This
# function returns no value.
sub clear_database() {
    $database->do(q[DELETE FROM branch_notes;]);
}

# Takes a branch name and a file handle.  If the database contains any
# notes for that branch then they will be written into the file.  This
# is intended to be used on the temporary file that use to add new
# notes so that users can edit existing notes.  We assume the file
# handle is already opened.  This function returns no value.
sub load_notes_for_branch($$) {
    my ($branch, $file) = @_;
    my $select = $database->prepare(q[
        SELECT notes
        FROM branch_notes
        WHERE name = ?;
    ]);

    $select->execute($branch);

    my $results = $select->fetchall_arrayref;

    if (@$results) {
        print $file $results->[0][0];
    }
}

# Process the 'show' command.  We display the name and notes for each
# branch on standard output.  The output format is in Markdown and
# uses multiple newlines to separate branches.  That is because
# personally I intended to often redirect the output of this command
# into emails, and those I always write in Markdown.
if ($command ~~ "show") {
    my $information = get_branch_information;

    # Are we showing notes only for a specific branch?
    if ($argument) {
        @$information = grep { $argument ~~ $_->[0] } @$information;
    }

    for my $branch (@$information) {
        say $branch->[0];
        say "=" x length($branch->[0]), "\n";
        say $branch->[1], "\n\n\n";
    }

    exit(0);
}

# Process the 'add' command.  This opens up the user's editor and
# reads in a note to save for the current branch.
if ($command ~~ "add") {
    my $current_branch = qx(git name-rev --name-only HEAD);
    strip_newlines_from $current_branch;

    # We store the notes in a temporary file that the user modifies
    # with the editor from above.  However, if the global variable
    # $argument is not empty then we treat that as the new notes to
    # add for the branch.  This makes it easy to add short messages
    # without opening the editor.
    my $notes_file = File::Temp->new();

    if ($argument) {
        print $notes_file $argument;
    }
    else {
        my $editor = get_editor;

        unless ($editor) {
            die("Error: No available editor to add notes\n");
        }

        load_notes_for_branch($current_branch, $notes_file);
        say "Adding notes for $current_branch";
        say "Waiting on $editor...";
        qx($editor $notes_file);
    }

    # Now read the entire contents of $notes_file into the scalar
    # $notes as a single string.  To do this we temporarily undefine
    # the special $/ variable so that the <> operator will read in
    # everything at once.  See 'perldoc perlfaq5' for information on
    # this trick.
    #
    # We also need to call seek() to rewind to the beginning of the
    # file just in case we wrote existing notes to it already,
    # otherwise <> will not read those existing notes.
    my $notes;
    {
        local $/ = undef;
        seek($notes_file, 0, 0);
        $notes = <$notes_file>;
    }

    save_notes_for_branch($current_branch, $notes);
    say "Saved notes for $current_branch";
    exit(0);
}

# Process the 'rm' command.  This takes a branch name and removes all
# information about that branch from our database of notes.  The name
# of the branch to remove will be in the global variable $argument.
if ($command ~~ "rm") {
    remove_branch($argument);
    say "Removed notes for $argument";
    exit(0);
}

# Process the 'clear' command.  This does the same thing as 'rm'
# except it removes the information about every branch in the
# database, wiping the entire thing clean.
if ($command ~~ "clear") {
    clear_database;
    say "Removed all branch notes";
    exit(0);
}

__END__
