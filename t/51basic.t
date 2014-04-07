#!/usr/bin/perl

use strict;
use warnings;

our $base = "50basic";

use File::Basename;
use File::Spec;
do File::Spec->catfile(dirname($0), "testscript.pl");
