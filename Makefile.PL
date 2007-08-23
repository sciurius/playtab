# Makefile.PL -- Makefile for App::Music::PlayTab
# Author          : Johan Vromans
# Created On      : Mon Feb  8 11:46:56 1999
# Last Modified By: Johan Vromans
# Last Modified On: Thu Aug 23 14:30:44 2007
# Update Count    : 74
# Status          : Stable

# Verify perl version.
require 5.000;

use ExtUtils::MakeMaker;

my @scripts = qw(playtab);

WriteMakefile
  (
   NAME         => 'App::Music::PlayTab',
   AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
   ABSTRACT	=> 'Print play tabs of songs',
   VERSION      => "0.06",
   PREREQ_PM	=> { 'Getopt::Long' => 2.00 },
   EXE_FILES    => [ map { "script/$_" } @scripts ],
   # *.pm files will be picked up automatically from ./lib
 );
