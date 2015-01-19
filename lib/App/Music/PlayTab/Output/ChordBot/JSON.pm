#!/usr/bin/perl

package App::Music::PlayTab::Output::ChordBot::JSON;

# Author          : Johan Vromans
# Created On      : Mon Apr 29 10:53:55 2013
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jan 19 13:06:37 2015
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

use Music::ChordBot::Opus;
use Music::ChordBot::Opus::Section;

# Init the backend.
sub setup {			# API
    my ( $self, $args ) = @_;
    $opus = Music::ChordBot::Opus->new;
    $opus->tempo($tempo) if $tempo;
    $section = Music::ChordBot::Opus::Section->new;
    $section->set_style($style) if $style;
    $opus->add_section($section);
    $chord = Music::ChordBot::Opus::Section::Chord->new;
}

# New page.
sub setuppage {			# API
    my ( $self, $title, $stitles ) = @_;
    return;			# N/A
}

sub finish {			# API
    my $self = shift;
    $section->add_chord($chord) if $chord->duration;
    $self->{fh}->print( $opus->json, "\n");
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
#	$self->$fun( @$ch );
    }
    else {
	my $fun = "render__$ch";
#	$self->$fun($dup);
    }
    while ( $dup-- > 1 ) {
	$self->render__space;
    }
}

sub _render {
    my ( $self, $ch, $dup ) = @_;

    if ( $ch->is_rest ) {
	$section->add_chord($chord) if $chord->duration;
	$chord = Music::ChordBot::Opus::Section::Chord->new(qw(A Silence 1));
    }
    else {
#	$ch->transpose($xpose) if $xpose;
	$section->add_chord($chord) if $chord->duration;
	$chord = Music::ChordBot::Opus::Section::Chord->new(qw(A Silence 1));
    }
    if ( my $d = $ch->duration ) {
	$d = int($d / ($ch->duration_base / 4));
	$chord->duration($d);
    }
    $chord->root( $ch->{key}->name );
    $chord->type( vec2type( "@{$ch->{vec}}" ) );
    $chord->bass( $ch->{bass}->[0]->name )
      if $ch->{bass};
}

sub render__space {
    my ( $self ) = @_;
    $chord->duration( 1 + $chord->duration );
}

sub bar {			# API
    my ( $self, $first ) = @_;
    return;			# N/A
}

sub newline {			# API
    my ( $self, $count ) = @_;
    return;			# N/A
}

sub postfix {			# API
    my ( $self, $text ) = @_;
    return;			# N/A
}

sub text {			# API
    my ( $self, $text, $xxmd, $font ) = @_;
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
