#!/usr/bin/perl

package App::Music::ChordBot;

# Author          : Johan Vromans
# Created On      : Mon Apr 29 10:53:55 2013
# Last Modified By: Johan Vromans
# Last Modified On: Sun Jan 18 16:32:38 2015
# Update Count    : 123
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

our $VERSION = "2.000";

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = ( 'playtab/chordbot', $VERSION );

use base qw(Exporter);
our @EXPORT = qw(run);

################ Command line parameters ################

use Getopt::Long;
sub app_options();

my $output;
my $preamble;
my $gxpose = 0;			# global xpose value
my $style;
my $tempo;
my $verbose = 0;		# verbose processing
my $lilypond = 0;		# use LilyPond syntax
my $export_api = 0;		# export Song API

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)

################ Presets ################

################ The Process ################

my $line;			# current line (for messages)
my $linetype = 0;		# type of current line
my $xpose = $gxpose;

use Music::ChordBot::Opus;
use Music::ChordBot::Opus::Section;
use Music::ChordBot::Opus::Section::Chord;

my $opus;
my $section;
my $chord;

sub run {
    local (@ARGV) = @_ ? @_ : @ARGV;

    app_options();

    if ( defined $output ) {
	open(OUTPUT, ">", $output);
    }
    else {
	*OUTPUT = *STDOUT;
    }

    # Options post-processing.
    $trace |= $debug;

    $opus = Music::ChordBot::Opus->new;
    $opus->tempo($tempo) if $tempo;
    $section = Music::ChordBot::Opus::Section->new;
    $section->set_style($style) if $style;
    $opus->add_section($section);
    $chord = Music::ChordBot::Opus::Section::Chord->new;

    while ( <> ) {

	if ( /^\s*##\s*ChordBot:\s*(.*)/ ) {
	    chordbot_control($1);
	    next;
	}

	next if /^\s*#/;
	next if $lilypond && /^\s*%/;
	$lilypond && s/\s+%\s*\d+\s*$//;
	next unless /\S/;
	chomp($line = $_);

	s/\^\s+//;
	if ( /^!\s*(.*)/ ) {
	    control($1);
	    next;
	}

	if ( /^\|/ ) {
	    $section->add_chord($chord) if $chord->duration;
	    $chord = Music::ChordBot::Opus::Section::Chord->new;
	    bar($_);
	    $linetype = 1;
	    next;
	}
	elsif ( $linetype == 1 && /^%?[-+=<]/ ) {
	    $section->add_chord($chord) if $chord->duration;
	    $chord = Music::ChordBot::Opus::Section::Chord->new;
	    $linetype = 0;
	}

	# Spacing/margin notes.
	if ( /^%?[-+=]\s*(.*)/ ) {
	    my $text = $1;
	    next unless $text =~ /\S/;
	    if ( @{ $section->chords } ) {
		$section = Music::ChordBot::Opus::Section->new;
		$section->no_style;
		$opus->add_section($section);
	    }
	    $text = $opus->name . ": " . $text if $opus->name;
	    $section->name($text);
	    $linetype = 0;
	    next;
	}
	if ( /^%?\</ ) {
	    print_margin(0, undef);
	    $linetype = 0;
	    next;
	}

	$linetype = 0;
    }

    $section->add_chord($chord) if $chord->duration;
    print OUTPUT $opus->export if $debug;
    if ( $export_api ) {
	print OUTPUT $opus->export_api;
    }
    elsif ( !$debug ) {
	print OUTPUT $opus->json, "\n";
    }
    close OUTPUT if defined $output;
}

################ Subroutines ################

sub Music::ChordBot::Opus::export_api {
    my ( $self, %args ) = @_;

    my $ir = "#! perl\n";
    $ir .= "\nuse strict;\nuse warnings;\nuse Music::ChordBot::Song 0.03;\n";
    $ir .= "\n";
    my $title = $self->{data}->{songName};
    $ir .= "song \"$title\";\n";
    my $tpat = quotemeta($title) . ": ";
    $ir .= "tempo " . $self->{data}->{tempo} . ";\n";
    $ir .= "\n";

    foreach my $section ( @{ $self->data->{sections} } )  {
	my $beatspermeasure = $section->{style}->{beats} // 4;
	my $beatstype = $section->{style}->{divider} // 4;

	my $t = $section->{name};
	$t = $1 if $t =~ /^$tpat(.*)/;
	$ir .= "section \"$t\";\n";

	my $beats = 0;
	my $dur = 0;
	foreach my $el ( @{ $section->{chords} } ) {
	    if ( $el->{is_a} eq "chord" ) {
		my $chord = $el;
		my $did = 0;

		if ( $chord->{type} =~ /^M(in|aj)$/ && !$chord->{bass} ) {
		    $ir .= $chord->{root};
		    $ir =~ s/#$/is/;
		    $ir =~ s/([BDG])b$/$1es/;
		    $ir =~ s/([AE])b$/$1s/;
		    $ir .= "m" if $chord->{type} eq "Min";
		    $ir .= " " . ( $dur = $chord->{duration} )
		      unless $chord->{duration} == $dur;
		    $ir .= "; ";
		}
		else {
		    $ir .= "chord \"" . $chord->{root};
		    $ir .= "/" . $chord->{bass} if $chord->{bass};
		    $ir .= " " . $chord->{type} . " " . $chord->{duration} . "\"; ";
		    $dur = $chord->{duration};
		}
		if ( ( $beats += $chord->{duration} ) >= 16 ) {
		    $ir .= "\n";
		    $dur = 0;
		    $beats = 0;
		}
		next;
	    }

	    if ( $el->{is_a} eq "timesig" ) {
		die("Cannot happen");
		next;
	    }
	    if ( $el->{is_a} eq "coda" ) {
		die("Cannot happen");
		next;
	    }
	    if ( $el->{is_a} eq "space" ) {
		die("Cannot happen");
		next;
	    }
	}
	$ir =~ s/\n*$/\n\n/;
    }
    $ir =~ s/ +\n/\n/g;
    $ir;
}

################ Subroutines ################

sub bar {
    my ($line) = @_;

    if ( $lilypond ) {
	# LilyPond chords use : and ., so don't split on these.
	$line =~ s/([|`'])/ $1 /g;	#'`])/;
    }
    else {
	$line =~ s/([|.:`'])/ $1 /g;	#'`])/;
    }
    $line =~ s/  +/ /g;

    my (@c) = split(' ', $line);
    my $firstbar = 1;

    while ( @c > 0 ) {
	eval {
	    my $c = shift(@c);
	    if ( $c eq '|' ) {
#		print_bar($firstbar);
		$firstbar = 0;
	    }
	    elsif ( $c eq ':' ) {
#		print_again();
	    }
	    elsif ( $c eq '.' ) {
		$chord->duration( 1 + $chord->duration );
	    }
	    elsif ( $c eq '%' ) {
		my $xs = 1;
		while ( @c > 0 && $c[0] eq '.' ) {
		    shift(@c);
		    $xs++;
		}
#		print_same('1', $xs);
	    }
	    elsif ( $c eq '-' ) {
		$section->add_chord($chord) if $chord->duration;
		$chord = Music::ChordBot::Opus::Section::Chord->new(qw(A Silence 1));
	    }
	    elsif ( $c eq '\'' ) {
	    }
	    elsif ( $c eq '`' ) {
	    }
	    elsif ( lc($c) eq 'ta' ) {
#		print_turnaround();
	    }
	    else {
		my $ch = parse_chord($c);

		if ( $ch->is_rest ) {
		    $section->add_chord($chord) if $chord->duration;
		    $chord = Music::ChordBot::Opus::Section::Chord->new(qw(A Silence 1));
		}
		else {
		    $ch->transpose($xpose) if $xpose;
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
	};
	die($@) if $@ =~ /can\'t locate/i;
	errout($@) if $@;
    }
}

sub control {
    local ($_) = @_;

    # Title.
    if ( /^t(?:itle)?\s+(.*)/i ) {
	$opus->name($1);
	return;
    }

    # Subtitle(s).
    if ( /^s(?:ub(?:title)?)?\s+(.*)/i ) {
	return;
    }

    # Width adjustment.
    if ( /^w(?:idth)?\s+([-+]?\d+)/i ) {
	return;
    }

    # Height adjustment.
    if ( /^h(?:eight)?\s+([-+]?\d+)/i ) {
	return;
    }

    # Margin width adjustment.
    if ( /^m(?:argin)?\s+([-+]?\d+)/i ) {
	return;
    }

    # Transpose.
    if ( /^x(?:pose)?\s+([-+])(\d+)/i ) {
	$xpose += $1.$2;
	return;
    }

    # Bar numbering
    if ( /^n(?:umber)?\s+([-+]?\d+)?/i ) {
	return;
    }

    # LilyPond syntax
    if ( /^l(?:y|ilypond)?(?:\s+(\d+))?/i ) {
	$lilypond = defined $1 ? $1 : 1;
	return;
    }

    if ( /^\>\s+(.+)/i ) {
	return;
    }

    errout("Unrecognized control");
}

sub chordbot_control {
    local ($_) = @_;
    if ( /^style\s+(.*)/i ) {
	# Don't override command line specified value.
	$section->set_style($1) unless $style;
	return;
    }
    if ( /^tempo\s+(.*)/i ) {
	# Don't override command line specified value.
	$opus->tempo(0+$1) unless $tempo;
	return;
    }

    errout("Unrecognized ChordBot control");
}

my $chordparser;
my $lilyparser;
sub parse_chord {
    my $chord = shift;
    my $parser;
    if ( $lilypond ) {
	unless ( $lilyparser ) {
	    require App::Music::PlayTab::LyChord;
	    $lilyparser = App::Music::PlayTab::LyChord->new;
	}
	$parser = $lilyparser;
    }
    else {
	unless ( $chordparser ) {
	    require App::Music::PlayTab::Chord;
	    $chordparser = App::Music::PlayTab::Chord->new;
	}
	$parser = $chordparser;
    }
    $parser->parse($chord);
}

my %vec2type;
sub vec2type {
    keys %vec2type or %vec2type =
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

=begin ignore

	"" => "7(#11)",
	"" => "7(#5)",
	"" => "7(#9)",
	"" => "7(b5)",
	"" => "7(b9)",
	"" => "7/6",
	"" => "7Add4",
	"" => "7Sus2",
	"" => "7Sus4",
	"" => "9Sus4",
	"" => "Add4",
	"" => "Add9",
	"" => "Aug7",
	"" => "AugAdd2",
	"" => "DimAdd4",
	"" => "Maj(#9)",
	"" => "Maj7(#11)",
	"" => "Maj7(#5)",
	"" => "Maj7(#9)",
	"" => "Maj7(b5)",
	"" => "Maj7(b9)",
	"" => "Maj7Sus4",
	"" => "Min6/9",
	"" => "Min7(#11)",
	"" => "Min7(#9)",
	"" => "Min7(b9)",
	"" => "Min7Sus4",
	"" => "MinAdd4",
	"" => "MinAdd9",
	"" => "MinMaj11",
	"" => "MinMaj7",
	"" => "MinMaj9",
	"" => "Silence",
	"" => "Sus2Sus4",

=cut

    $vec2type{$_[0]} || "Silence";
}

sub errout {
    my $msg = "@_";
    $msg =~ s/ at .*line \d+.*//s;
    warn("$msg\n", "Line $.: $line\n");
}

################ Command Line Options ################

sub app_ident;
sub app_usage($);

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions('output=s'	=> \$output,
		     'transpose|x=i' => \$gxpose,
		     'style=s'	=> \$style,
		     'tempo=i'	=> \$tempo,
		     'export_api|api' => \$export_api,
		     'ident'	=> \$ident,
		     'verbose'	=> \$verbose,
		     'trace'	=> \$trace,
		     'help'	=> \$help,
		     'debug'	=> \$debug,
		    )
	 or abs($gxpose) > 11 )
    {
	app_usage(2);
    }
    app_ident if $ident;
    app_usage(0), syntax(), exit(0) if $help;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage($) {
    my ($exit) = @_;
    app_ident;
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    --output XXX	output file name
    --transpose +/-N    transpose all
    --lilypond		use LilyPond chord syntax
    --help		this message
    --ident		show identification
    --verbose		verbose information
EndOfUsage
    exit $exit if $exit != 0;
}

sub syntax {
    print STDERR <<EOD;
Not-es: C, D, E, F, G, A, B.
Raised with '#' or suffix 'is', e.g. A#, Ais.
Lowered with 'b' or suffix 's' or 'es', e.g. Bes, As, Eb.

Chords: note + optional modifiers.
Chord modifiers Meaning                 [examples]
--------------------------------------------------------------
nothing         major triad             [C]
- or min or m   minor triad             [Cm Fmin Gb-]
+ or aug        augmented triad         [Caug B+]
o or 0 or dim   diminished triad        [Co D0 Fdim]
--------------------------------------------------------------
maj7            major 7th chord         [Cmaj7]
%               half-diminished 7 chord [C%]
6,7,9,11,13     chord additions         [C69]
sus sus4, sus2  suspended 4th, 2nd      [Csus]
--------------------------------------------------------------
#               raise the pitch of the note to a sharp [C11#9]
b               lower the pitch of the note to a flat [C11b9]
--------------------------------------------------------------
no              substract a note from a chord [C9no11]
--------------------------------------------------------------
() and _ may be used to avoid ambiguity, e.g. C(#9) <-> C#9 <-> C#_9

Other:          Meaning
--------------------------------------------------------------
.               Chord space
-               Rest
:               Repeats previous chord
%               Repeat pattern
/               Powerchord constructor   [D/G D/E-]
--------------------------------------------------------------

EOD
}

################ Documentation ################

=head1 NAME

App::Music::PlayTab - Print chords of songs in a tabular fashion.

=head1 SYNOPSIS

=head2 playtab

playtab [options] [file ...]

 Options:
   --transpose +/-N     transpose all songs
   --output XXX		set outout file
   --lilypond		accept chords in LilyPond syntax
   --ident		show identification
   --help		brief help message
   --verbose		verbose information

=head2 App::Music::PlayTab

 use App::Music::PlayTab;
 run();			# arguments in @ARGV
 run(@args);		# explicit arguments

 perl -MApp::Music::PlayTab -e run ...arguments...

=head1 DESCRIPTION

This utility program is intended for musicians. It produces tabular
chord diagrams that are very handy for playing rhythm guitar or bass
in jazz, blues, and popular music.

I wrote it since in official (and unofficial) sheet music, I find it
often hard to stick to the structure of the piece. Also, as a guitar
player, I do not need all the detailed notes and such that are only
important for melody instruments. And I cannot turn over the pages
while playing.

For more info and examples,
see http://johan.vromans.org/software/sw_playtab.html .

B<playtab> is just a trivial wrapper around the App::Music::PlayTab module.

=head1 COMMAND LINE OPTIONS

=over 8

=item B<--transpose> I<amount>

Transposes all songs by I<amount>. This can be B<+> or B<-> 11 semitones.

When transposing up, chords will de represented sharp if necessary;
when transposing down, chords will de represented flat if necessary.
For example, chord A transposed +1 will become A-sharp, but when
transposed -11 it will become B-flat.

=item B<--output> I<file>

Designates I<file> as the output file for the program.

=item B<--lilypond>

Interpet chord names according to LilyPond syntax.

=item B<--help>

Print a brief help message and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

More verbose information.

=item I<file>

Input file(s).

=back

=head1 INPUT SYNTAX

The input for playtab is plain ASCII. It contains the chords, the
division in bars, with optional annotations.

An example:

    !t Blue Bossa

    Bossanova
    =
    | c-9 ... | f-9 ... | d% . g7 . | c-9 ... |
    | es-9 . as6 . | desmaj7 ... | d% . g7 . | c-9 . d% g7 |

The first line, '!t' denotes the title of the song. Each song must
start with a title line.

The title line may be followed by one or more '!s', subtitles, for
example to indicate the composer.

The text "Bossanova" is printed below the title and subtitle.

The "=" indicates some vertical space. Likewise, you can use '-' and
'+' as '=', but with a different vertical spacing.

The next lines show the bars of the song. In the first bar is the c-9
chord (Cminor9), followed by three dots. The dots indicate that this
chord is repeated for all 4 beats of this bar. In the 3rd bar each
chord take two beats: d5% (d half dim), a dot, g7 and another dot.

Run playtab with B<-h> or B<--help> for the syntax of chords.

If you use "=" followed by some text, the printout is indented and the
text sticks out to the left. With this you can tag groups of bars, for
example the parts of a song that must be played in a certain order.
For example:

    !t Donna Lee
    !s Charlie Parker

    Order: A B A B

    = A
    | as . | f7 . | bes7 . | bes7 . |
    | bes-7 . | es7 . | as . | es-7 D7 |
    | des . | des-7 . | as . | f7 . |
    | bes7 . | bes7 . | bes-7 . | es7 . |

    = B
    | as . | f7 . | bes7 . | bes7 . |
    | c7 . | c7 . | f- . | c7#9 . |
    | f- . | c7 . | f- . | aso . |
    | as f7 | bes-7 es7 | as - | bes-7 es7 |

To see how this looks, see http://johan.vromans.org/software/sw_playtab.html .

You can modify the width of the bars with a '!w' control. Standard
width of a beat is 30. '!w +5' increases the width to 35. '!w 25' sets
it to 25. You get the idea. You can also change the height with '!h'
(default is 15) and margin with '!m' (default width is 40).

You can transpose an individual song with '!x I<amount>', where
I<amount> can range from -11 to +11, inclusive. A positive transpose
value will make sharps, a negative value will make flats.

'!n' enables bar numbering. '!n 0' disables numbering, '!n I<n>'
starts numbering at I<n>. I<n> may be negative, e.g., to skip
numbering an intro.

'!ly' or '!lilypond' enables LilyPond chord name recognition. If
followed by a '0', switches to classical chord name syntax.

Look at the examples, that is (currently) the best way to get grip on
what the program does.

Oh, I almost forgot: it can print guitar chord diagrams as well.
See "bluebossa", "sophisticatedlady" and some others.

Have fun, and let me know your ideas!

=head1 INPUT SYNTAX

  Notes: C, D, E, F, G, A, B.
  Raised with '#' or suffix 'is', e.g. A#, Ais.
  Lowered with 'b' or suffix 's' or 'es', e.g. Bes, As, Eb.

  Chords: note + optional modifiers.
  Chord modifiers Meaning                 [examples]
  --------------------------------------------------------------
  nothing         major triad             [C]
  - or min or m   minor triad             [Cm Fmin Gb-]
  + or aug        augmented triad         [Caug B+]
  o or 0 or dim   diminished triad        [Co D0 Fdim]
  --------------------------------------------------------------
  maj7            major 7th chord         [Cmaj7]
  %               half-diminished 7 chord [C%]
  6,7,9,11,13     chord additions         [C69]
  sus sus4, sus2  suspended 4th, 2nd      [Csus]
  --------------------------------------------------------------
  #               raise the pitch of the note to a sharp [C11#9]
  b               lower the pitch of the note to a flat [C11b9]
  --------------------------------------------------------------
  no              substract a note from a chord [C9no11]
  --------------------------------------------------------------
  _ may be used to avoid ambiguity, e.g. C_#9 <-> C#9 <-> C#_9

  Other:          Meaning
  --------------------------------------------------------------
  .               Chord space
  -               Rest
  :               Repeats previous chord
  %               Repeat
  /               Powerchord constructor   [D/G D/E-]
  --------------------------------------------------------------

=head1 LILYPOND INPUT SYNTAX

  Notes: c, d, e, f, g, a, b.
  Raised with suffix 'is', e.g. ais.
  Lowered with suffix 'es', e.g. bes, ees.

  Chords: note + optional duration + optional modifiers.

  Duration = 1, 2, 4, 8, with possible dots, e.g., "2.".
  No duration means: use the duration of the previous chord.

  Modifiers are preceeded with a ":".

  Modifiers       Meaning                 [examples]
  --------------------------------------------------------------
  nothing         major triad             c4
  m               minor triad             c4:m
  aug             augmented triad         c4:aug
  dim             diminished triad        c4:dim
  --------------------------------------------------------------
  maj             major 7th chord         c4:maj
  6,7,9,11,13     chord additions         c4:7  c4:6.9 (dot required)
  sus sus4, sus2  suspended 4th, 2nd      c4:sus
  --------------------------------------------------------------
  +               raise the pitch of an added note   c4:11.9+
  -               lower the pitch of an added note   c4:11.9-
  --------------------------------------------------------------
  ^               substract a note from a chord      c4:9.^11
  --------------------------------------------------------------

  Other:          Meaning
  --------------------------------------------------------------
  r               Rest                    r2
  s               Rest                    s4
  /               Powerchord constructor  d/g   d/e:m
  --------------------------------------------------------------

See also: http://lilypond.org/doc/stable/Documentation/user/lilypond/Chord-names

=head1 SEE ALSO

http://chordie.sourceforge.net/

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy E<lt>jvromans@squirrel.nlE<gt>

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 1990,2013 by Johan Vromans.

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
