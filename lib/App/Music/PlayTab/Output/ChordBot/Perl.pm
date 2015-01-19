#!/usr/bin/perl

package App::Music::PlayTab::Output::ChordBot::Perl;

# Author          : Johan Vromans
# Created On      : Mon Apr 29 10:53:55 2013
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jan 19 13:05:09 2015
# Update Count    : 171
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

use Music::ChordBot::Opus;
use Music::ChordBot::Opus::Section;

EOD
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
    $type .= "/" . $ch->{bass}->[0]->name if $ch->{bass};
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
    App::Music::PlayTab::Output::ChordBot::vec2type($_[0]) || "Silence";
}

1;
