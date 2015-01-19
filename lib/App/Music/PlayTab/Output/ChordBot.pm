#!/usr/bin/perl

package App::Music::PlayTab::Output::ChordBot;

# Author          : Johan Vromans
# Created On      : Mon Apr 29 10:53:55 2013
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jan 19 13:13:04 2015
# Update Count    : 176
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

our $VERSION = "2.01";

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

################ The Process ################

sub new {			# API
    my ( $pkg, $args ) = @_;

    # Basically, we have multiple backends in here.
    # ::ChordBot::JSON generates ready to play ChordBot (JSON data).
    # ::ChordBot::Perl generates a Perl program that uses the
    # ChordBot modules to generate the same JSON, but that can be
    # modified after generation for specific purposes beyond the scope
    # of PlayTab.
    # ::ChordBot::Song is similar to Perl, but uses the more friendly
    # Song API.
    # The decision what backend to use is based on the name of the
    # generator, or, if missing, the name of the output file.

    if ( $args->{output} && $args->{output} =~ /\.p[lm]$/ ) {
	# Wants Perl source.
	$pkg = 'App::Music::PlayTab::Output::ChordBot::Perl';
	require App::Music::PlayTab::Output::ChordBot::Perl;
    }
    else {
	$pkg = 'App::Music::PlayTab::Output::ChordBot::JSON';
	require App::Music::PlayTab::Output::ChordBot::JSON;
    }

    bless { init => 0 }, $pkg
}

################ Subroutines ################

# Some routines for the backends to use.

my %vec2type;

sub vec2type {
    setup_vec2type() unless %vec2type;
    $vec2type{$_[0]};
}

sub setup_vec2type {
    %vec2type =
      (
       "0 3 6"		    => "Min(b5)",
       "0 3 6 9"	    => "Dim",
       "0 3 6 10"	    => "Dim7",		# Min7(b5)

       "0 3 7"		    => "Min",
       "0 3 7 9"	    => "Min6",
       "0 3 7 10"	    => "Min7",
       "0 3 7 10 14"	    => "Min9",
       "0 3 7 10 14 17"	    => "Min11",
       "0 3 7 10 14 18 21"  => "Min13",

       "0 3 8"		    => "Min(#5)",
       "0 3 8 10"	    => "Min7(#5)",

       "0 4 6"		    => "Maj(b5)",

       "0 4 7"		    => "Maj",
       "0 4 7 9"	    => "6",
       "0 4 7 9 10 14"	    => "6/9",
       "0 4 7 10"	    => "7",
       "0 4 7 10 14"	    => "9",
       "0 4 7 10 14 17"	    => "11",
       "0 4 7 10 14 18 21"  => "13",
       "0 4 7 11"	    => "Maj7",
       "0 4 7 11 14"	    => "Maj9",
       "0 4 7 11 14 17"	    => "Maj11",
       "0 4 7 11 14 18 21"  => "Maj13",

       "0 4 8"		    => "Aug",

       "0 5 7"		    => "Sus4",

       "0 7"		    => "Sus2",
      );
}

1;
