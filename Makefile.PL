# Makefile.PL -- Makefile for Music::PlayTab
# Author          : Johan Vromans
# Created On      : Mon Feb  8 11:46:56 1999
# Last Modified By: Johan Vromans
# Last Modified On: Fri Feb 12 19:45:31 1999
# Update Count    : 66
# Status          : Stable

# Verify perl version.
require 5.000;

use ExtUtils::MakeMaker;

my @scripts = qw(playtab);

WriteMakefile
  (
   NAME         => 'Music::PlayTab',
   AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
   ABSTRACT	=> 'Print play tabs of songs',
   VERSION      => "0.01",
   PREREQ_PM	=> { 'Getopt::Long' => 2.00 },
   EXE_FILES    => [ map { "scripts/$_" } @scripts ],
   # *.pm files will be picked up automatically from ./lib
 );
