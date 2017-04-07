#!/usr/bin/perl

use strict;
use warnings;

our $base = "60lilypond";

use lib qw(.);			# for perl 2.26+
use File::Basename;
use File::Spec;

$ENV{PLAYTABTEST_EXT} = "dmp";

do File::Spec->catfile(dirname($0), "testscript.pl");
