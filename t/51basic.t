#!/usr/bin/perl

use strict;
use warnings;

our $base = "50basic";

use lib qw(.);			# for perl 2.26+
use File::Basename;
use File::Spec;
do File::Spec->catfile(dirname($0), "testscript.pl");
