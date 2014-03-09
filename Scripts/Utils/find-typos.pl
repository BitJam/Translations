#!/usr/bin/perl

use Getopt::Long;
use English;

use strict;
use warnings;
my $ME = $0; $ME =~ s{.*/}{};

my $LANG_FILE="en.sh";
my $RC_FILE="linuxrc";
my ($UNDO, $QUIET, $VERBOSE);

my %VALID_VAR;
my %XLATE;
my %ERROR;
my $ERR_CNT = 0;
my $FNAME;

my (@IGNORE, %IGNORE);

sub error($$);

my $USAGE = <<Usage;
Usage: $ME [options]

Checks to see that all the translations variables in a linuxrc file
match all the translation variables in an en.sh file.  Translation
variables begin and end with an underscore.  If the --undo options
is given and there were no errors then the linuxrc file is translated
and the translation is printed on stdout.  

Options
    --trfile <file>   The translation file.  Default: $LANG_FILE
    --rcfile <file>   The linuxrc file.      Default: $RC_FILE
    --undo            Print the translation on stdout.
    --ignore <error>  Errors to ignore.
    --help            Show this help.
    --verbose         Print more
    --quiet           print less
Usage

GetOptions(
    "trfile=s" => \$LANG_FILE,
    "rcfile=s" => \$RC_FILE,
    undo       => \$UNDO,
    quiet      => \$QUIET,
    verbose    => \$VERBOSE,
    "ignore=s" => \@IGNORE,
    help       => sub { print $USAGE; exit },
) or die $USAGE;

@ARGV and do {
    warn "$ME: extra command line arguments: @ARGV\n";
    die  "$ME: use -h or --help for help.\n";
};

%IGNORE = map { lc $_ => 1 } @IGNORE;

open my $lang_handle, "<", $LANG_FILE or die "Could not open($LANG_FILE) $!";
$FNAME = $LANG_FILE;

while(<$lang_handle>) {
    s/^(\w+?)=// or next;
    my $var = $1;
    chomp;
    s/^"(.*)"/$1/;
    s/^'(.*)'/$1/;

    $var =~ /^_\w+_$/ or do {
        error "Bad var", $var;
        next;
    };
    $VALID_VAR{$var} = 0;
    $XLATE{$var} = $_;

    #print "$1\n";

}

close $lang_handle;

open my $rc_handle, "<", $RC_FILE or die "Could not open($RC_FILE) $!";
$FNAME = $RC_FILE;

while (<$rc_handle>) {
    my $line = $_;
    for my $var ( m/\$(\w+)/g, m/\$\{(\w+)\}/ ) {
        $var =~ /^_[a-zA-Z]\w*_$/ or do {
            $var =~ /^_/ and error "Suspicious var", $var;
            $var =~ /_$/ and error "Suspicious var", $var;
            next;
        };

        exists $VALID_VAR{$var} and do {
            $VALID_VAR{$var}++;
            next;
        };
        error "Unknown var", $var;
    }
    for my $var ($line =~ /([^\$\w]_\w+_)/ ) {
        error "Missing dollar", $var;
    }
}
close $rc_handle;

for my $var (sort keys %VALID_VAR) {
    my $val = $VALID_VAR{$var};
    $val > 0 and next;
    error "Not used", $var;
}

$QUIET or do {
    if ($ERR_CNT) {
        warn sprintf "$ME %3d error(s)\n", $ERR_CNT;
    }
    else {
        print "No errors.\n";
    }
};
        

$VERBOSE and do {
    for my $type (sort keys %ERROR) {
        warn sprintf "$ME: %3d %s error(s)\n", $ERROR{$type}, $type;
    }
};

$UNDO or exit;

$ERR_CNT && do {
    warn "Not undoing.\n";
    exit;
};

open $rc_handle, "<", $RC_FILE or die "Could not open($RC_FILE) $!";
$FNAME = $RC_FILE;

while (<$rc_handle>) {
    s/\$(_\w+_)\b/xlate_var($1)/ge;       # $_var_name_
    s/\$\{(_\w+_)\}\b/xlate_var($1)/ge;   # ${_var_name_}
    print;
}

close $rc_handle;

#==============================================================================

sub xlate_var {
    my $var = shift;
    exists $XLATE{$var} or return $var;
    return $XLATE{$var};
}

sub error($$) {
    my ($type, $var) = @_;
    $IGNORE{lc $type} and return;
    $ERROR{$type}++;
    $ERR_CNT++;
    warn sprintf qq{%s: in %8s \@ line %4d: %s "%s"\n}, 
        $ME, $FNAME, $INPUT_LINE_NUMBER, $type, $var;
}

