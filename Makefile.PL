# Makefile.PL -- Makefile for App::Music::PlayTab
# Author          : Johan Vromans
# Created On      : Mon Feb  8 11:46:56 1999
# Last Modified By: Johan Vromans
# Last Modified On: Wed Apr 26 20:22:21 2017
# Update Count    : 83
# Status          : Stable

# Verify perl version.
require 5.008;

use ExtUtils::MakeMaker;

my $master = 'lib/App/Music/PlayTab.pm';
my $version = MM->parse_version($master);

my @scripts = qw(playtab);

WriteMakefile
  (
   NAME         => 'App::Music::PlayTab',
   AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
   ABSTRACT	=> 'Print play tabs (griles, grids) of songs',
   VERSION_FROM => $master,
   PREREQ_PM	=> {
      Clone => 0,
      App::Packager => 1.420,
     },
   EXE_FILES    => [ map { "script/$_" } @scripts ],
   TEST_REQUIRES => {
      Test::More => 0,
     },

   META_MERGE => {
      license => "perl_5",
      resources => {
	 homepage => "http://johan.vromans.org/software/sw_playtab.html"
	},
      provides => {
	 playtab =>
	   { file => "script/playtab", version => $version },
	 App::Music::PlayTab =>
	   { file => $master, version => $version },
	},
      no_index => {
         directory => [
	    "lib/App/Music/PlayTab",
	   ],
	},
     },
  );
