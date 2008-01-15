#!/usr/bin/perl

use strict;
use warnings;

# Sorry, can't use Test::More here...
# use Test::More tests => 6;

print "1..6\n";

our $base;

my $prefix = "";
my $script = "";

if ( -d "t" ) {
    $prefix = "t/";
    $script = "script/playtab";
}
else {
    $script = "../script/playtab";
}

{ package PlayTab;
  @ARGV = ("-test",
	   "-output", "${prefix}test.ps",
	   "-preamble", "${prefix}dummy.pre",
	   "${prefix}${base}.ptb");
  require($script);
}

my $ok = !differ ("${prefix}test.ps", "${prefix}${base}.ps");
unlink ("${prefix}test.ps") if $ok;
print $ok ? "" : "not ", "ok 6\n";

sub differ {
    # Perl version of the 'cmp' program.
    # Returns 1 if the files differ, 0 if the contents are equal.
    my ($old, $new) = @_;
    unless ( open (F1, $old) ) {
	print STDERR ("$old: $!\n");
	return 1;
    }
    unless ( open (F2, $new) ) {
	print STDERR ("$new: $!\n");
	return 1;
    }
    my ($buf1, $buf2);
    my ($len1, $len2);
    while ( 1 ) {
	$len1 = sysread (F1, $buf1, 10240);
	$len2 = sysread (F2, $buf2, 10240);
	return 0 if $len1 == $len2 && $len1 == 0;
	return 1 if $len1 != $len2 || ( $len1 && $buf1 ne $buf2 );
    }
}

