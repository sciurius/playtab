#! perl

use strict;
use warnings;

# Collect the test cases from the data file.
my @tests;
BEGIN {
    my $td;
    open($td, "<", "03chord.dat")
      or open($td, "<", "t/03chord.dat")
	or die("03chord.dat: $!\n");
    while ( <$td> ) {
	next unless /\S/;
	next if /^#/;
	chomp;
	push(@tests, $_);
    }
    close($td);
}

use Test::More tests => 1 + 2 * @tests;
BEGIN {
    use_ok qw(App::PlayTab::Chord);
}

# Run the tests.
# Input is
# chord <TAB> name <TAB> ps

foreach ( @tests ) {
    my ($chord, $name, $ps) = split(/\t/, $_);
    $name ||= $chord;
    my $c = App::PlayTab::Chord->parse($chord);
    my $res = $c->name;
    is($res, $name, "$chord: name");
    ok(1, "$chord: no ps"), next unless $ps;
    $res = $c->ps;
    is($res, $ps, "$chord: ps");
}
