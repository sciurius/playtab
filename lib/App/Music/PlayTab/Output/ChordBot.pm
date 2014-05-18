#!/usr/bin/perl

package App::Music::PlayTab::Output::ChordBot;

# Author          : Johan Vromans
# Created On      : Mon Apr 29 10:53:55 2013
# Last Modified By: Johan Vromans
# Last Modified On: Sun May 18 23:51:03 2014
# Update Count    : 139
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

our $VERSION = "2.000";

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

################ The Process ################

sub new {			# API
    my ( $pkg, $args ) = @_;

    # Basically, we have two backends in here.
    # ::ChordBot generates ready to play ChordBot (JSON data).
    # ::ChordBotPl generates a Perl program that uses the
    # ChordBot modules to generate the same JSON, but that can be
    # modified after generation for specific purposes beyond the scope
    # of PlayTab.
    # The decision what backend to use is based on the name of the
    # output file.

    if ( $args->{output} && $args->{output} =~ /\.p[lm]$/ ) {
	# Wants Perl source.
	$pkg = 'App::Music::PlayTab::Output::ChordBot::Perl';
    }
    else {
	$pkg = 'App::Music::PlayTab::Output::ChordBot::JSON';
    }
    bless { init => 0 }, $pkg
}

my $opus;
my $section;
my $chord;

my $tempo = 120;
my $style = "Kubiac";
my %vec2type;

package App::Music::PlayTab::Output::ChordBot::Perl;

# Init the backend.
sub setup {			# API
    my ( $self, $args ) = @_;

    $self->{fh}->print( <<EOD );
#! perl

use strict;
use warnings;

use Music::ChordBot::Opus;
use Music::ChordBot::Opus::Section;

EOD
    App::Music::PlayTab::Output::ChordBot::setup_vec2type($self);
}

# New page.
sub setuppage {			# API
    my ( $self, $title, $stitles ) = @_;

    $self->{fh}->print( <<EOD );
# The song.
my \$song = Music::ChordBot::Opus->new( name => q{$title}, tempo => $tempo );
EOD

    if ( $stitles ) {
	$self->{fh}->print( "# ", $_, "\n" ) foreach @$stitles;
    }

    $self->{fh}->print( <<EOD );

# One section.
my \$section = Music::ChordBot::Opus::Section->new( name => "Section1" );

# Set a rather stupid default style.
\$section->set_style("$style");
EOD

    return;			# N/A
}

sub finish {			# API
    my $self = shift;
#    $section->add_chord($chord) if $chord->duration;
    $self->{fh}->print( <<'EOD' );

# Add section to song.
$song->add_section($section);

# Export as json.
print( $song->json, "\n" );
EOD
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

sub _render {
    my ( $self, $ch, $dup ) = @_;

    my $name = "C";
    my $dur = $ch->duration;
    my $type = "Silence";

    if ( $ch->is_rest ) {
    }
    else {
	$name = $ch->{key}->name;
	$type = vec2type( "@{$ch->{vec}}" );
    }
    if ( $dur ) {
	$dur = int($dur / ($ch->duration_base / 4));
    }
    else {
	$dur = $dup;
    }
    $self->{fh}->print( "\$section->add_chord( ",
			"\"$name\", \"$type\", $dur );\n");
}

sub render__rest { }

sub bar {			# API
    my ( $self, $first ) = @_;
    $self->{fh}->print("\n") if $first;
    return;
}

sub newline {			# API
    my ( $self, $count ) = @_;
    return;			# N/A
}

sub postfix {			# API
    my ( $self, $text ) = @_;
    $self->{fh}->printf( "# >> %s\n", $text );
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
    $vec2type{$_[0]} || "Silence";
}

package App::Music::PlayTab::Output::ChordBot::JSON;

# Init the backend.
sub setup {			# API
    my ( $self, $args ) = @_;
    $opus = Music::ChordBot::Opus->new;
    $opus->tempo($tempo) if $tempo;
    $section = Music::ChordBot::Opus::Section->new;
    $section->set_style($style) if $style;
    $opus->add_section($section);
    $chord = Music::ChordBot::Opus::Section::Chord->new;
    $self->setup_vec2type;
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
    $vec2type{$_[0]} || "Silence";
}

package App::Music::PlayTab::Output::ChordBot;

sub setup_vec2type {
    %vec2type =
      (
       "0 3 6"		    => "Min(b5)",
       "0 3 6 9"	    => "Dim",
       "0 3 6 10"	    => "Dim7",
#       "0 3 6 10"	    => "Min7(b5)",

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
#       "0 4 7"		    => "5",
       "0 4 7 9"	    => "6",
       "0 4 7 9 10 14"	    => "6/9",
#       "0 4 7 9 10 14"	    => "9/6",
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
