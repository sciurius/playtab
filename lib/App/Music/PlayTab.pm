#!/usr/bin/perl

package App::Music::PlayTab;

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Tue Apr 19 16:32:40 2011
# Update Count    : 369
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

our $VERSION = "2.022";

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = ( 'playtab', $VERSION );

use base qw(Exporter);
our @EXPORT = qw(run);

################ Command line parameters ################

use Getopt::Long;
sub app_options();

my $output;
my $preamble;
my $gxpose = 0;			# global xpose value
my $verbose = 0;		# verbose processing
my $lilypond = 0;		# use LilyPond syntax

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test

################ Presets ################

# Print dimensions.
my $std_width	   =  30;
my $std_height	   = -15;
my $std_margin	   =  40;
my $std_gridscale  =   8;

my @Rom = qw(I II III IV V VI VII VIII IX X XI XII);

################ The Process ################

my $line;			# current line (for messages)
my $linetype = 0;		# type of current line
my $posttext;

my $xpose = $gxpose;

sub run {
    local (@ARGV) = @_ ? @_ : @ARGV;

    app_options();
    print STDOUT ("ok 1\n") if $test;

    if ( defined $output ) {
	open(OUTPUT, ">$output") or print STDOUT ("not ") if $test;
	print STDOUT ("ok 2\n") if $test;
    }
    else {
	die("Test mode requires -output option to be set\n") if $test;
	*OUTPUT = *STDOUT;
    }

    # Options post-processing.
    $trace |= ($debug || $test);

    ps_preamble();
    print STDOUT ("ok 3\n") if $test;

    while ( <> ) {
	next if /^\s*#/;
	next if $lilypond && /^\s*%%/;
	next unless /\S/;
	chomp($line = $_);

	s/\^\s+//;
	if ( /^!\s*(.*)/ ) {
	    control($1);
	    next;
	}

	if ( /^\s*\[/ ) {
	    while ( /^\s*\[([^]]+)\](.*)/ ) {
		eval { chord($1) };
		errout($@) if $@;
		$_ = $2;
	    }
	    $linetype = 2;
	    next;
	}
	elsif ( $linetype == 2 ) {
	    print_newline(4);
	    $linetype = 0;
	}

	if ( /^\s*\|/ ) {
	    print_newline() if $linetype;
	    bar($_);
	    $linetype = 1;
	    next;
	}
	elsif ( $linetype == 1 && /^%?[-+=<]/ ) {
	    print_newline();
	    $linetype = 0;
	}

	# Spacing/margin notes.
	if ( /^%?=(.*)/ ) {
	    print_margin(2, $1);
	    $linetype = 0;
	    next;
	}
	if ( /^%?-(.*)/ ) {
	    print_margin(1, $1);
	    $linetype = 0;
	    next;
	}
	if ( /^%?\+(.*)/ ) {
	    print_margin(0, $1);
	    $linetype = 0;
	    next;
	}
	if ( /^%?\</ ) {
	    print_margin(0, undef);
	    $linetype = 0;
	    next;
	}

	text($_);
	$linetype = 0;
    }
    print STDOUT ("ok 4\n") if $test;

    ps_trailer ();
    print STDOUT ("ok 5\n") if $test;

    close OUTPUT if defined $output;
    exit 0 unless $test;
}

################ Subroutines ################

sub bar {
    my ($line) = @_;

    on_top();

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
		print_bar($firstbar);
		$firstbar = 0;
	    }
	    elsif ( $c eq ':' ) {
		print_again();
	    }
	    elsif ( $c eq '.' ) {
		print_space();
	    }
	    elsif ( $c eq '%' ) {
		my $xs = 1;
		while ( @c > 0 && $c[0] eq '.' ) {
		    shift(@c);
		    $xs++;
		}
		print_same('1', $xs);
	    }
	    elsif ( $c eq '-' ) {
		print_rest();
	    }
	    elsif ( $c eq '\'' ) {
		ps_skip(4);
	    }
	    elsif ( $c eq '`' ) {
		ps_skip(-4);
	    }
	    elsif ( lc($c) eq 'ta' ) {
		print_turnaround();
	    }
	    else {
		ps_move();
		my $chord = parse_chord($c);

		if ( $chord->is_rest ) {
		    print_rest();
		}
		else {
		    $chord->transpose($xpose) if $xpose;
		    print_chord($chord);
		    ps_step();
		}
		if ( my $d = $chord->duration ) {
		    $d = int($d / ($chord->duration_base / 4));
		    unshift(@c, ('.') x ($d-1));
		}
	    }
	};
	die($@) if $@ =~ /can\'t locate/i;
	errout($@) if $@;
    }
    if ( defined $posttext ) {
	ps_skip(4);
	ps_move();
	print OUTPUT ('SF (', $posttext, ') show', "\n");
	undef $posttext;
    }
    print_newline();
}

sub control {
    local ($_) = @_;

    # Title.
    if ( /^t(itle)?\s+(.*)/i ) {
	print_title(1, $+);
	return;
    }

    # Subtitle(s).
    if ( /^s(ub(title)?)?\s+(.*)/i ) {
	print_title(0, $+);
	return;
    }

    # Width adjustment.
    if ( /^w(idth)?\s+([-+]?\d+)/i ) {
	ps_set_width($2);
	return;
    }

    # Height adjustment.
    if ( /^h(eight)?\s+([-+]?\d+)/i ) {
	ps_set_height($2);
	return;
    }

    # Margin width adjustment.
    if ( /^m(argin)?\s+([-+]?\d+)/i ) {
	ps_set_margin($2);
	return;
    }

    # Transpose.
    if ( /^x(pose)?\s+([-+])(\d+)/i ) {
	$xpose += $2.$3;
	return;
    }

    # Bar numbering
    if ( /^n(umber)?\s+([-+]?\d+)?/i ) {
	set_barno(defined $2 ? $2 ? $2 < 0 ? $2+1 : $2 : undef : 1);
	return;
    }

    # LilyPond syntax
    if ( /^l(?:y|ilypond)?(?:\s+(\d+))?/i ) {
	$lilypond = defined $1 ? $1 : 1;
	return;
    }

    if ( /^\>\s+(.+)/i ) {
	$posttext = $1;
	return;
    }


    errout("Unrecognized control");
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

sub chord {
    my (@l) = split(' ',$_[0]);

    die("Illegal [chord] spec, need 7 or 8 values")
	unless @l == 8 || @l == 7;

    my $chord = parse_chord(shift(@l));

    my @c = ();
    my $c = '()';
    foreach ( @l ) {
	$_ = -1 if lc($_) eq "x";
	if ( /^@(\d+)/ ) {
	    $c = "($Rom[$1-1])" if $1 > 1;
	    next;
	}
	die("Illegal [chord] spec, need 6 numbers")
	    unless /^-?\d$/ || @c == 6;
	push(@c, $_);
    }

    on_top();

    my $ps = $chord->ps;
    print OUTPUT ('1000 1000 moveto', "\n",
		  $ps, "\n",
		  'currentpoint pop 1000 sub 2 div', "\n");
    ps_move();
    print OUTPUT (2.5*$std_gridscale, ' exch sub 8 add 0 rmoveto ',
		  $ps, "\n");
    ps_move();
    print OUTPUT ('8 ', -5-(4*$std_gridscale), " rmoveto @c $c dots\n");
    ps_skip(80);
}

sub text {
    my ($line) = @_;
    ps_push_actual_margin(0);
    on_top();
    ps_move();
    print OUTPUT ('SF (', $line, ') show', "\n");
    ps_advance();
    ps_pop_actual_margin();
}

sub errout {
    my $msg = "@_";
    $msg =~ s/ at .*line \d+.*//s;
    warn("$msg\n", "Line $.: $line\n");
}

################ Print Routines ################

my $x0 = 0;
my $y0 = 0;
my $x = 0;
my $y = 0;
my $xd = 0;
my $yd = 0;
my $xw = 0;
my $yd_width = 0;
my $xm = 0;
my $md = 0;
my $on_top = 0;
my $barno;

sub set_barno {
    $barno = shift;
}

sub print_title {
    my ($new, $title) = @_;

    if ( $new ) {
	ps_page();
    }
    ps_move();
    print OUTPUT ($new ? 'TF (' : 'SF (', $title, ') show', "\n");
    ps_advance();
    $on_top = 1;
    undef $barno;
    $xpose = $gxpose;
}

# begin scope for $prev_chord
my $prev_chord;

sub print_chord {
    my($chord) = @_;
    print OUTPUT ($chord->ps, "\n");
    $prev_chord = $chord;
}

sub print_again {
    ps_move();
    print OUTPUT ($prev_chord->ps, "\n");
    ps_step();
}

# end scope for $prev_chord

sub print_bar {
    my ($first) = @_;
    ps_move();
    if ( defined($barno) ) {
	if ( $first ) {
	    print OUTPUT $barno > 0 ? ("($barno) barn\n") : ("bar\n");
	}
	else {
	    print OUTPUT ("bar\n");
	    $barno++;
	}
    }
    else {
	print OUTPUT ("bar\n");
    }
    ps_skip(4);
}

sub print_newline {
    &ps_advance;
}

sub print_space {
    ps_step();
}

sub print_rest {
    ps_move();
    print OUTPUT ("rest\n");
    ps_step();
}

sub print_same {
    my ($wh, $xs) = @_;
    ps_push_x(($xs * $xd) / 2);
    ps_move();
    print OUTPUT ("same$wh\n");
    ps_pop_x();
    ps_skip($xs * $xd);
}

sub print_turnaround {
    ps_move();
    print OUTPUT ("ta\n");
    ps_step();
}

sub print_margin {
    my ($full, $margin) = @_;
    unless ( on_top() ) {
	ps_advance($full);
    }
    $xm = 0, return unless defined $margin;
    return unless $margin =~ /\S/;
    $margin =~ s/^\s+//;
    $margin =~ s/\s$//;
    $xm = 0;
    ps_move();
    print OUTPUT ('SF (', $margin, ') show', "\n");
    $xm = $md;
}

sub on_top {
    return 0 unless $on_top;
    $x = 0;
    $y = 4*$yd;
    $on_top = 0;
    return 1;
}

################ PostScript routines ################

my $ps_pages = 0;

sub ps_page {
    print OUTPUT ('end showpage', "\n") if $ps_pages;
    print OUTPUT ('%%Page: ', ++$ps_pages. ' ', $ps_pages, "\n",
		  'tabdict begin', "\n");
    $x = $y = $xm = 0;
    $xd = $std_width;
    $yd = $std_height;
    $md = $std_margin;
}

sub ps_set_margin {
    my $v = shift;
    croak("ps_set_margin: number or increment\n")
      unless $v =~ /^([-+])?(\d+)$/;
    if ( defined $1 ) {
	$md += $1.$2;
    }
    else {
	$md = $2;
    }
}

my @oldmargin;
sub ps_push_actual_margin {
    push(@oldmargin, $xm);
    $xm = shift;
}

sub ps_pop_actual_margin {
    $xm = pop(@oldmargin);
}

sub ps_set_width {
    my $v = shift;
    croak("ps_set_width: number or increment\n")
      unless $v =~ /^([-+])?(\d+)$/;
    if ( defined $1 ) {
	$xd += $1.$2;
    }
    else {
	$xd = $2;
    }
}

sub ps_set_height {
    my $v = shift;
    croak("ps_set_height: number or increment\n")
      unless $v =~ /^([-+])?(\d+)$/;
    if ( defined $1 ) {
	$yd -= $1.$2;
    }
    else {
	$yd = -$2;
    }
}

sub ps_move {
    print OUTPUT ($x0+$x+$xm, ' ' , $y0+$y, ' m ');
}

sub ps_step {
    $x += $xd;
}

sub ps_advance {
    $x = 0;
    $y += $yd;
    $y += ($_[0]-1)*$yd if defined $_[0];
}

sub ps_skip {
    $x += $_[0];
}

my @oldx;
sub ps_push_x {
    push(@oldx, $x);
    $x += shift;
}

sub ps_pop_x {
    $x = pop(@oldx);
}

sub ps_preamble {
    my $data;
    if ( defined $preamble ) {
	open(DATA, $preamble) or die("$preamble: $!\n");
	local($/);
	$data = <DATA>;
	close(DATA);
    }
    else {
	require App::Music::PlayTab::PostScript::Preamble;
	$data = App::Music::PlayTab::PostScript::Preamble->preamble;
    }
    $data =~ s/\$std_gridscale/$std_gridscale/g;
    print OUTPUT ($data);

    $x0 = 50;
    $y0 = 800;
    $xd = $std_width;
    $yd = $std_height;
    $x = $y = $xm = 0;
    $ps_pages = 0;
}

sub ps_trailer {
    print OUTPUT <<EOD;
end showpage
%%Trailer
%%Pages: $ps_pages
%%EOF
EOD
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
		     'preamble=s' => \$preamble,
		     'transpose|x=i' => \$gxpose,
		     'ident'	=> \$ident,
		     'verbose'	=> \$verbose,
		     'trace'	=> \$trace,
		     'help'	=> \$help,
		     'test'	=> \$test,
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

This program is Copyright 1990,2008 by Johan Vromans.

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
