#!/usr/bin/perl

package App::Music::PlayTab::Output::ChordBot::Song;

# Author          : Johan Vromans
# Created On      : Mon Apr 29 10:53:55 2013
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jan 19 13:05:01 2015
# Update Count    : 174
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

our $VERSION = "2.01";

use App::Music::PlayTab::Output::ChordBot;

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

################ The Process ################

sub new {			# API
    my ( $pkg, $args ) = @_;
    bless { init => 0 }, $pkg
}

my $opus;
my $section;
my $chord;

my $tempo = 120;
my $style = "Kubiac";
my %vec2type;

# Init the backend.
sub setup {			# API
    my ( $self, $args ) = @_;

    $self->{fh}->print( <<EOD );
#! perl

use strict;
use warnings;

use Music::ChordBot::Song;

EOD
    App::Music::PlayTab::Output::ChordBot::setup_vec2type($self);
}

# New page.
sub setuppage {			# API
    my ( $self, $title, $stitles ) = @_;

    $self->{fh}->print( <<EOD );
song "$title";
tempo $tempo;
EOD

    if ( $stitles ) {
	$self->{fh}->print( "# ", $_, "\n" ) foreach @$stitles;
    }

    $self->{fh}->print( <<EOD );

# One section.
section "Section1";

# Set a rather stupid default style.
style "$style";
EOD

    return;			# N/A
}

sub finish {			# API
    my $self = shift;
    $self->{fh}->print("\n");
}

# New print line.
sub setupline {			# API
    my ( $self, $line ) = @_;
    return;			# N/A
}

sub chord {			# API
    my ( $self, $ch, $dup ) = @_;

    if ( ref($ch) =~ /::/ ) {
	$self->_render( $ch, $dup );
	$self->{_prev_chord} = $ch;
    }
    elsif ( ref($ch) eq 'ARRAY' ) {
	my $fun = "render__" . shift(@$ch);
	$self->$fun( @$ch );
    }
    else {
	my $fun = "render__$ch";
	$self->$fun($dup);
    }
}

my $pdur = -1;

sub _render {
    my ( $self, $chord, $dup ) = @_;

    my $name = "C";
    my $dur = $chord->duration;
    my $type = "Silence";

    if ( $chord->is_rest ) {
    }
    else {
	$name = $chord->{key}->name;
	$type = vec2type( "@{$chord->{vec}}" );
    }
    if ( $dur ) {
	$dur = int($dur / ($chord->duration_base / 4));
    }
    else {
	$dur = $dup;
    }

    $type = vec2type( "@{$chord->{vec}}" );

    if ( $type =~ /^M(in|aj)$/ && !$chord->bass ) {
	my $ir = $chord->{key}->name;
	$ir =~ s/#$/is/;
	$ir =~ s/([BDG])b$/$1es/;
	$ir =~ s/([AE])b$/$1s/;
	$ir .= "m" if $type eq "Min";
	$ir .= " " . $dur unless $dur == $pdur;
	$self->{fh}->print( $ir, "; ");
    }
    else {
	$type .= "/" . $chord->{bass}->[0]->name if $chord->{bass};
	$self->{fh}->print( "chord ",
			    "\"$name\", \"$type\", $dur; ");
    }
    $pdur = $dur;
}

sub render__rest { }

sub bar {			# API
    my ( $self, $first ) = @_;
    $pdur = -1, $self->{fh}->print("\n") if $first;
    return;
}

sub newline {			# API
    my ( $self, $count ) = @_;
    return;			# N/A
}

sub postfix {			# API
    my ( $self, $text ) = @_;
    $self->{fh}->printf( "\t# %s\n", $text );
    return;			# N/A
}

sub text {			# API
    my ( $self, $text, $xxmd, $font ) = @_;
    $self->{fh}->printf( "\n# %s\n", $text );
    return;			# N/A
}

sub grids {			# API
    my ( $self, $grids ) = @_;
    return;			# N/A
}

sub vec2type {
    App::Music::PlayTab::Output::ChordBot::vec2type($_[0]) || "Silence";
}

1;
