#!/usr/bin/perl
my $RCS_Id = '$Id$ ';

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Tue Feb 20 12:39:30 2007
# Update Count    : 110
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
# Tack '*' if it is not checked in into RCS.
$my_version .= '*' if length('$Locker$ ') > 12;

################ Command line parameters ################

use Getopt::Long;
sub app_options();

my $output;
my $preamble;
my $gxpose = 0;			# global xpose value
my $verbose = 0;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test

app_options();
print STDOUT ("ok 1\n") if $test;

if ( defined $output ) {
    open (OUTPUT, ">$output") or print STDOUT ("not ") if $test;
    print STDOUT ("ok 2\n") if $test;
}
else {
    die ("Test mode requires -output option to be set\n") if $test;
    *OUTPUT = *STDOUT;
}

# Options post-processing.
$trace |= ($debug || $test);

################ Presets ################

# All notes, using sharps.
my @SNotes =
  # 0    1    2    3    4    5    6    7    8    9    10   11
  ('C ','C#','D ','D#','E ','F ','F#','G ','G#','A ','A#','B ');
# All notes, using flats.
my @FNotes =
  # 0    1    2    3    4    5    6    7    8    9    10   11
  ('C ','Db','D ','Eb','E ','F ','Gb','G ','Ab','A ','Bb','B ');
# The current mapping.
my $Notes;

# Reverse mapping (plain notes only).
my %Notemap;
for ( my $i = 0; $i < @SNotes; $i++ ) {
    $Notemap{$1} = $i if $SNotes[$i] =~ /(.) /;
}

# Print dimensions.
my $std_width  = 30;
my $std_height = -15;
my $std_margin = 40;
my $std_gridscale = 8;

my $ps_pages = 0;

my @Rom = ('', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX',
	   'X', 'XI', 'XII');

################ The Process ################

my $linetype = 0;
my $line;

my $x0 = 0;
my $y0 = 0;
my $x = 0;
my $y = 0;
my $xd = 0;
my $yd = 0;
my $xm = 0;
my $xw = 0;
my $yd_width = 0;
my $md = 0;
my $on_top = 0;
my $xpose = $gxpose;

# Globals.
use vars qw($chord @vec $key $chordname);

ps_preamble();
print STDOUT ("ok 3\n") if $test;

while ( <> ) {
    next if /^\s*#/;
    next unless /\S/;
    chop ($line = $_);

    s/\^\s+//;
    if ( /^!\s*(.*)/ ) {
	control ($1);
	next;
    }

    if ( /^\s*\[/ ) {
	while ( /^\s*\[([^]]+)\](.*)/ ) {
	    chord ($1);
	    $_ = $2;
	}
	$linetype = 2;
	next;
    }
    elsif ( $linetype == 2 ) {
        ps_advance ();
        ps_advance ();
        ps_advance ();
        ps_advance ();
	$linetype = 0;
    }

    if ( /^\s*\|/ ) {
	ps_advance () if $linetype;
	bar ($_);
	$linetype = 1;
	next;
    }
    elsif ( $linetype == 1 && /^[-+=]/ ) {
	ps_advance ();
	$linetype = 0;
    }

    # Spacing/margin notes.
    if ( /^=(.*)/ ) {
	advance (2, $1);
	$linetype = 0;
	next;
    }
    if ( /^-(.*)/ ) {
	advance (1, $1);
	$linetype = 0;
	next;
    }
    if ( /^\+(.*)/ ) {
	advance (0, $1);
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

################ Subroutines ################

sub print_title {
    my ($new, $title) = @_;

    if ( $new ) {
	print OUTPUT ('end showpage', "\n") if $ps_pages;
	print OUTPUT ('%%Page: ', ++$ps_pages. ' ', $ps_pages, "\n",
		      'tabdict begin', "\n");
	$x = $y = $xm = 0; 
	$xd = $std_width; $yd = $std_height; $md = $std_margin;
    }
    ps_move ();
    print OUTPUT ($new ? 'TF (' : 'SF (', $title, ') show', "\n");
    ps_advance ();
    $on_top = 1;
    $xpose = $gxpose;
    # Use sharps when xposing up, flats when xposing down.
    $Notes = $xpose > 0 ? \@SNotes : \@FNotes;
}

my $prev_chord;

sub print_chord {
    $prev_chord = ps_chordname ();
    print OUTPUT ($prev_chord, "\n");
}

sub print_again {
    ps_move ();
    print OUTPUT ($prev_chord, "\n");
    ps_step ();
}

sub print_bar {
    ps_move ();
    print OUTPUT ("bar\n");
    $x += 4;
}

sub print_newline {
    ps_advance ();
}

sub print_space {
    ps_step ();
}

sub print_rest {
    ps_move ();
    print OUTPUT ("rest\n");
    ps_step ();
}

sub print_same {
    my ($wh, $xs) = @_;
    { my $xsave = $x;
      $x += ($xs * $xd) / 2;
      ps_move ();
      print OUTPUT ("same$wh\n");
      $x = $xsave;
    }
    $x += $xs * $xd;
}

sub print_turnaround {
    ps_move ();
    print OUTPUT ("ta\n");
    ps_step ();
}

sub advance {
    my ($full, $margin) = @_;
    unless ( on_top() ) {
	$x = 0;
	$y += $yd * $full;
    }
    return unless $margin =~ /\S/;
    $margin =~ s/^\s+//;
    $margin =~ s/\s$//;
    $xm = 0;
    ps_move ();
    print OUTPUT ('SF (', $margin, ') show', "\n");
    $xm = $md;
}

sub bar {
    my ($line) = @_;
    local ($chord, $key, @vec);

    on_top ();

    $line =~ s/([|.:`'])/ $1 /g;	#'`])/;
    $line =~ s/  +/ /g;

    my (@c) = split (' ', $line);
    while ( @c > 0 ) {
	my $c = shift (@c);
	if ( $c eq '|' ) {
	    print_bar ();
	    next;
	}
	elsif ( $c eq ':' ) {
	    print_again ();
	    next;
	}
	elsif ( $c eq '.' ) {
	    print_space ();
	    next;
	}
	elsif ( $c eq '%' ) {
	    my $xs = 1;
	    while ( @c > 0 && $c[0] eq '.' ) {
		shift (@c);
		$xs++;
	    }
	    print_same ('1', $xs);
	    next;
	}
	elsif ( $c eq '-' ) {
	    print_rest ();
	    next;
	}
	elsif ( $c eq '\'' ) {
	    ps_kern (1);
	    next;
	}
	elsif ( $c eq '`' ) {
	    ps_kern (-1);
	    next;
	}
	elsif ( $c eq 'ta' || $c eq 'TA' ) {
	    print_turnaround ();
	    next;
	}

	ps_move ();
	my (@ch) = split ('/',$c);
	while ( @ch > 1 ) {
	    my $c = shift (@ch);
	    ($chord, $key, @vec) = parse_chord ($c);
	    print_chord ($chord, $key, @vec);
	    print OUTPUT ("slash\n");
	}
	($chord, $key, @vec) = parse_chord ($ch[0]);
	print_chord ($chord, $key, @vec);
	ps_step ();
    }
    print_newline ();
}

sub control {
    local ($_) = @_;

    # Title.
    if ( /^t(itle)?\s+(.*)/i ) {
	print_title (1, $+);
	return;
    }

    # Subtitle(s).
    if ( /^s(ub(title)?)?\s+(.*)/i ) {
	print_title (0, $+);
	return;
    }

    # Width adjustment.
    if ( /^w(idth)?\s+([-+])?(\d+)/i ) {
	if ( defined $2 ) {
	    $xd += $2.$3;
	}
	else {
	    $xd = $3;
	}
	return;
    }

    # Height adjustment.
    if ( /^h(eight)?\s+([-+])?(\d+)/i ) {
	if ( defined $2 ) {
	    $yd -= $2.$3;
	}
	else {
	    $yd = -$3;
	}
	return;
    }

    # Margin width adjustment.
    if ( /^m(argin)?\s+([-+])?(\d+)/i ) {
	if ( defined $2 ) {
	    $md += $2.$3;
	}
	else {
	    $md = $3;
	}
	return;
    }

    # Transpose.
    if ( /^x(pose)?\s+([-+])(\d+)/i ) {
	$xpose += $2.$3;
	# Use sharps when xposing up, flats when xposing down.
	$Notes = $xpose > 0 ? \@SNotes : \@FNotes;
	return;
    }

    errout ("Unrecognized control");
}

sub chord {
    my (@l) = split(' ',$_[0]);
    my $xpose = 0;		#### TODO: WHY?

    errout ("Illegal [chord] spec, need 7 or 8 values")
	unless @l == 8 || @l == 7;
    local ($chordname, $key, @vec) = parse_chord (shift(@l));

    my @c = ();
    my $c = '()';
    foreach ( @l ) {
	$_ = -1 if "\L$_" eq "x";
	if ( /^@(\d+)/ ) {
	    $c = "($Rom[$1])" if $1 > 1;
	    next;
	}
	errout ("Illegal [chord] spec, need 6 numbers")
	    unless /^-?\d$/ || @c == 6;
	push (@c, $_);
    }

    on_top ();
    $chordname = ps_chordname ();
    print OUTPUT ('1000 1000 moveto', "\n",
		  $chordname, "\n",
		  'currentpoint pop 1000 sub 2 div', "\n");
    ps_move ();
    print OUTPUT (2.5*$std_gridscale, ' exch sub 8 add 0 rmoveto ',
		  $chordname, "\n");
    ps_move ();
    print OUTPUT ('8 ', -5-(4*$std_gridscale), " rmoveto @c $c dots\n");
    $x += 40 + 40;
}

sub text {
    my ($line) = @_;
    my $xmsave = $xm;
    $xm = 0;
    on_top ();
    ps_move ();
    print OUTPUT ('SF (', $line, ') show', "\n");
    ps_advance ();
    $xm = $xmsave;
}

sub on_top {
    return 0 unless $on_top;
    $x = 0;
    $y = 4*$yd;
    $on_top = 0;
    return 1;
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
}

sub ps_kern {
    my ($k) = @_;
    $x += $k * 4;
}

sub ps_preamble {
    if ( defined $preamble ) {
	open (DATA, $preamble) or die ("$preamble: $!\n");
    }
    while ( <DATA> ) {
	s/\$std_gridscale/$std_gridscale/g;
	print OUTPUT ($_);
    }
    $x0 = 50; $y0 = 800; $xd = $std_width; $yd = $std_height;
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

sub parse_note {
    my ($note) = @_;

    # Parse note name and return internal code.
    # Side-effect: sets $use_flat if appropriate.

    # Trim.
    $note =~ s/\s+$//;

    # Get out if relative scale specifier.
    return '*' if $note eq '*';

    my $res;

    # Try sharp notes, e.g. Ais, C#.
    if ( $note =~ /^([a-g])(is|\#)$/i ) {
	$res = $Notemap{uc($1)} + 1;
	$res = 0 if $res >= 12;
	$Notes = \@SNotes unless $xpose;
    }
    # Try flat notes, e.g. Es, Bes, Db.
    elsif ( $note =~ /^([a-g])(e?s|b)$/i ) {
	$res = $Notemap{uc($1)} - 1;
	$res = 11 if $res < 0;
	$Notes = \@FNotes unless $xpose;
    }
    # Try plain note, e.g. A, C.
    elsif ( $note =~ /^([a-g])$/i ) {
	$res = $Notemap{uc($1)};
    }
    # No more tries.
    else {
	errout ("Unrecognized note name \"$note\"");
    }

    # Return.
    print STDERR ("=ch=> $note -> $res\n") if $debug;
    $res;
}

sub parse_chord {
    local ($chord) = @_;

    $chord = "\L$chord";
    my $mod;

    # Separate the chord key from the modifications.
    if ( $chord =~ /(^[a-g*](\#|b|s|es|is)?)(.*)/ ) {
	$key = $1;
	$mod = $3;
	$mod = chop($key) . $mod
	    if $1 eq 's' && substr($3,0,2) eq 'us';
    }
    else {
	$key = $chord;
	$mod = '';
    }

    # Parse key.
    print STDERR ("=pc=> $chord -> [$key,$mod]\n") if $debug;
    $key = parse_note ($key);

    # Encodings: a bit is set in $chflags for every note in the chord.
    # The corresponding element of $chmods is 0 (natural), -1
    # (lowered), 1 (raised) or undef (suppressed).

    my $chflags = '';
    my @chmods = (0) x 14;

    # Assume major triad.
    vec($chflags,3,1) = 1;
    vec($chflags,5,1) = 1;
    $chmods[3] = 0;
    $chmods[5] = 0;

    $mod =~ s/^-/min/;		# Minor triad
    $mod =~ s/^\+/aug/;		# Augmented triad
    $mod =~ s/^0/dim/;		# Diminished

    # Then other modifications.
    while ( $mod ne '' ) {
	if ( $mod =~ /^[(). ](.*)/ ) {	# syntactic sugar
	    $mod = $+;
	    next;
	}
	if ( $mod =~ /^maj7?(.*)/ ) {	# Maj7
	    $mod = $+;
	    vec($chflags,7,1) = 1;
	    $chmods[7] = 1;
	    next;
	}
	if ( $mod =~ /^(min|m)(.*)/ ) {	# Minor triad
	    $mod = $+;
	    vec($chflags,3,1) = 1;
	    $chmods[3] = -1;
	    next;
	}
	if ( $mod =~ /^sus4?(.*)/ ) {	# Suspended fourth
	    $mod = $+;
	    vec($chflags,4,1) = 1;	# does it?
	    undef $chmods[3];
	    $chmods[4] = 0;
	    next;
	}
	if ( $mod =~ /^aug(.*)/ ) {		# Augmented
	    $mod = $+;
	    vec($chflags,5,1) = 1;
	    $chmods[5] = 1;
	    next;
	}
	if ( $mod =~ /^(o|dim)(.*)/ ) {	# Diminished
	    $mod = $+;
	    vec($chflags,3,1) = 1;
	    vec($chflags,5,1) = 1;
	    vec($chflags,7,1) = 1;
	    $chmods[3] = -1;
	    $chmods[5] = -1;
	    $chmods[7] = -1;
	    next;
	}
	if ( $mod =~ /^%(.*)/ ) {	# half-diminished 7
	    $mod = $+;
	    $chflags = '';
	    vec($chflags,3,1) = 1;
	    vec($chflags,5,1) = 1;
	    vec($chflags,7,1) = 1;
	    $chmods[3] = -1;
	    $chmods[5] = -1;
	    $chmods[7] = 0;
	    next;
	}
	if ( $mod =~ /^([\#b])?(5|6|7|9|10|11|13)(.*)/ ) { # addition
	    $mod = $+;
	    # 13th implies 11th implies 9th implies 7th...
	    if ( $2 > 7 && !(vec($chflags,7,1)) ) {
		vec($chflags,7,1) = 1;
		$chmods[7] = 0;
	    }
	    if ( $2 > 10 && !(vec($chflags,9,1)) ) {
		vec($chflags,9,1) = 1;
		$chmods[9] = 0;
	    }
	    if ( $2 > 11 && !(vec($chflags,11,1)) ) {
		vec($chflags,11,1) = 1;
		$chmods[11] = 1;
	    }
	    vec($chflags,$2,1) = 1;
	    $chmods[$2] = 0;
	    if ( defined $1 ) {
		$chmods[$2] = ($1 eq '#') ? 1 : -1;
	    }
	    next;
	}
	if ( $mod =~ /^no\s*(\d+)(st|nd|rd|st)?(.*)/ ) {
	    $mod = $+;
	    vec($chflags,$1,1) = 1;
	    undef $chmods[$1];
	    next;
	}
	errout ("Unknown chord modification: \"$mod\"");
	last;
    }

    @vec = (0);
    for (1..13) {
	next unless vec($chflags,$_,1);
	next unless defined $chmods[$_];
	push (@vec, (0,0,2,4,5,7,9,10,12,14,16,17,19,21)[$_]+$chmods[$_]);
    }
    $chord = chordname ();
    print STDERR ("=pc=> $chord -> $key\[@vec]\n") if $debug;
    ("\u$chord", $key, @vec);

    # TODO: maug
}

sub chordname {
    my $res = $Notes->[$key eq '*' ? 0 : $key];
    $res =~ s/\s+$//;

    my @v = @vec;
    shift (@v);

    my $v = "@vec ";
    print STDERR ("=cn=> $v\n") if $debug;
    if ( $v =~ s/^0 4 (6|7|8) / / ) {
	$res .= $1 == 8 ? '+' : '';
	$v = ' 6' . $v if $1 == 6;
    }
    elsif ( $v =~ s/^0 3 6 9 / / ) {
	$res .= 'o';
    }
    elsif ( $v =~ s/^0 3 (6|7|8) / / ) {
	if ( $1 == 6 ) {
	    $res .= ( $v =~ s/^ 10 // ) ? '%' : 'o';
	}
	else {
	    $res .= 'm';
	}
	$v = ' 8' . $v if $1 == 8;
    }
    $v =~ s/^0 5 7 / 5 7 /;
    $v =~ s/ 10 14 18 (21) / $1 /;		# 13
    $v =~ s/ 10 14 18 (20|22) / 10 $1 /;	#  7#13 7b13
    $v =~ s/ 10 14 (17) / $1 /;			# 11
    $v =~ s/ 10 14 (18) / 10 $1 /;		#  7#11
    $v =~ s/ 10 (14) / $1 /;			#  9
    $v =~ s/ 10 (15) / 10 $1 /;			#  7#9
    $v =~ s/ 11 14 18 (21|22) / $1 11 /;	# 13#5
    $v =~ s/ 11 14 (17|18) / $1 11 /;		# 11#5
    $v =~ s/ 11 (14|15) / $1 11 /;		#  9#5
    if ( $v =~ s/ 10 / / ) {
	$res .= '7';
    }
    elsif ( $v =~ s/^( \d| 10)* 11 / $1/ ) {
	$res .= 'maj7';
    }
    print STDERR ("=cn=> $v\n") if $debug;
    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	$res .= '('.('1','b2','2','b3','3','4','b5','5','#5','6','7','#7','8','b9','9','#9','b11','11','#11','12','b13','13')[$_].')';
    }
    my $res0 = $res;
    $res =~ s/^([^\(]*[^\d])?\((\d+)\)([^\d][^\(]*)?$/$1$2$3/;
    $res =~ s/7?(6|\(6\))(9|\(9\))/6.9/;
    $res =~ s/(4|\(4\))(5|\(5\))/sus4/;
    print STDERR ("=cn=> $chord -> $res0 -> $res\n") if $debug;
    $res;
}

sub ps_chordname {
    my $res = $Notes->[$key eq '*' ? 0 : (($key+$xpose)%12)];
    $res =~ s/\s+$//;
    if ( $res =~ /(.)b/ ) {
	$res = '('.$1.') root flat ';
    }
    elsif ( $res =~ /(.)#/ ) {
	$res = '('.$1.') root sharp ';
    } 
    else {
	$res = '('.$res.') root ';
    }

    my @v = @vec;
    shift (@v);

    my $v = "@vec ";
    print STDERR ("=cn=> $v\n") if $debug;
    if ( $v =~ s/^0 4 (6|7|8) / / ) {
	$res .= $1 == 8 ? 'plus ' : '';
	$v = ' 6' . $v if $1 == 6;
    }
    elsif ( $v =~ s/^0 3 6 9 / / ) {
	$res .= 'dim ';
    }
    elsif ( $v =~ s/^0 3 (6|7|8) / / ) {
	if ( $1 == 6 ) {
	    $res .= ( $v =~ s/^ 10 // ) ? 'hdim' : 'dim';
	}
	else {
	    $res .= 'minus ';
	}
	$v = ' 8' . $v 	if $1 == 8;
    }
    $v =~ s/^0 5 7 / 5 7 /;
    $v =~ s/ 10 14 18 (21) / $1 /;		# 13
    $v =~ s/ 10 14 18 (20|22) / 10 $1 /;	#  7#13 7b13
    $v =~ s/ 10 14 (17) / $1 /;			# 11
    $v =~ s/ 10 14 (18) / 10 $1 /;		#  7#11
    $v =~ s/ 10 (14) / $1 /;			#  9
    $v =~ s/ 10 (15) / 10 $1 /;			#  7#9
    $v =~ s/ 11 14 18 (21|22) / $1 11 /;	# 13#5
    $v =~ s/ 11 14 (17|18) / $1 11 /;		# 11#5
    $v =~ s/ 11 (14|15) / $1 11 /;		#  9#5
    if ( $v =~ s/ 10 / / ) {
	$res .= '(7) addn ';
    }
    elsif ( $v =~ s/^( \d| 10)* 11 / $1/ ) {
	$res .= '-2 0 rmoveto ' if $res =~ /flat $/;
	$res .= 'delta ';
    }
    if ( $v =~ s/ 5 7 / / ) {
	$res .= '(4) susp ';
    }
    print STDERR ("=cn=> $v\n") if $debug;
    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	$res .= ('(1) addn ','(2) addf ','(2) addn ','(3) addf ','(3) addn ',
		 '(4) addn ','(5) addf ','(5) addn ','(5) adds ','(6) addn ',
		 '(7) addn ','(7) adds ','(8) addn ','(9) addf ','(9) addn ',
		 '(9) adds ','(11) addf ','(11) addn ','(11) adds ',
		 '(12) addn ','(13) addf ','(13) addn ')[$_];
    }
    print STDERR ("=cn=> $chord -> $res\n") if $debug;
    $res;
}

sub errout {
    my (@msg) = @_;
    print STDERR (join (' ', @msg), "\n",
		  "Line $.: $line\n");
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
    app_usage (0), syntax(), exit(0) if $help;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage($) {
    my ($exit) = @_;
    app_ident;
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    -output XXX		output file name
    -transpose +/-N     transpose all
    -help		this message
    -ident		show identification
    -verbose		verbose information
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
--------------------------------------------------------------
#               raise the pitch of the note to a sharp [C11#9]
b               lower the pitch of the note to a flat [C11b9]
--------------------------------------------------------------
no              substract a note from a chord [C9no11]
--------------------------------------------------------------
Whitespace and () may be used to avoid ambiguity, e.g. C(#9) <-> C#9 <-> C#(9)

Other:          Meaning
--------------------------------------------------------------
.               Chord space
-               Rest
%               Repeat
/               Powerchord constructor   [D/G D/E-]
--------------------------------------------------------------

EOD
}

################ Documentation ################

=head1 NAME

playtab - print chords of songs

=head1 SYNOPSIS

playtab [options] [file ...]

 Options:
   -output XXX		set outout file
   -ident		show identification
   -help		brief help message
   -verbose		verbose information

=head1 OPTIONS

=over 8

=item B<-output> I<file>

Designates I<file> as the output file for the program.

=item B<-help>

Print a brief help message and exits.

=item B<-ident>

Prints program identification.

=item B<-verbose>

More verbose information.

=item I<file>

Input file(s).

=back

=head1 DESCRIPTION

The input for playtab is plan ASCII. It contains the chords, the
division in bars, with optional annotations.

An example:

    !t Blue Bossa

    Bossanova
    =
    | c-9 ... | f-9 ... | d% . g7 . | c-9 ... |
    | es-9 . as6 . | desmaj7 ... | d% . g7 . | c-9 . d% g7 |

The first line, '!t' denotes the title of the song. Each song must
start with a title line.

The title line may be followed by '!s', a subtitle, for example to
indicate the composer.

The text "Bossanova" is printed below the title and subtitle.

The "=" indicates some vertical space.

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

You can modify the width of the bars with a '!w' control. Standard
width of a beat is 30. '!w +5' increases the width to 35. '!w 25' sets
it to 25. You get the idea. You can also change the height with '!h'
(default is 15) and margin with '!m' (default width is 40).

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
  --------------------------------------------------------------
  #               raise the pitch of the note to a sharp [C11#9]
  b               lower the pitch of the note to a flat [C11b9]
  --------------------------------------------------------------
  no              substract a note from a chord [C9no11]
  --------------------------------------------------------------
  Whitespace and () may be used to avoid ambiguity, e.g. C(#9) <-> C#9 <-> C#(9)

  Other:          Meaning
  --------------------------------------------------------------
  .               Chord space
  -               Rest
  %               Repeat
  /               Powerchord constructor   [D/G D/E-]
  --------------------------------------------------------------

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy E<lt>jvromans@squirrel.nlE<gt>

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 1990,1999 by Johan Vromans.
This program is free software; you can redistribute it and/or
modify it under the terms of the Perl Artistic License or the
GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

If you do not have a copy of the GNU General Public License write to
the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
MA 02139, USA.


=cut

__END__
%!PS-Adobe-2.0
%%Pages: (atend)
%%DocumentFonts: Helvetica
%%EndComments
%%BeginProcSet: Symbols 0
/tabdict 50 dict def 
tabdict begin
/m { moveto } bind def
/dim {
    currentpoint
    /MSyms findfont 18 scalefont setfont
    1 -2 rmoveto (@) show moveto } def
/hdim {
    currentpoint
    /MSyms findfont 18 scalefont setfont 
    1 -2 rmoveto (^) show moveto } def
/minus {
    currentpoint
    /Symbol findfont 12 scalefont setfont
    1 8 rmoveto (-) show moveto } def
/plus {
    currentpoint
    /Symbol findfont 12 scalefont setfont
    1 8 rmoveto (+) show moveto } def
/delta {
    /Symbol findfont 12 scalefont setfont 
    1 -3 rmoveto (D) show -1 3 rmoveto } def
/sharp {
    /MSyms findfont 13 scalefont setfont
    2 0 rmoveto (f) show -1 0 rmoveto } def
/flat {
    /MSyms findfont 16 scalefont setfont 
    2 -2 rmoveto (s) show -2 2 rmoveto } def
/natural {
    /MSyms findfont 13 scalefont setfont
    2 0 rmoveto (d) show -1 0 rmoveto } def
/addn {
    /Helvetica findfont 12 scalefont setfont 
    0 -3 rmoveto show 0 3 rmoveto } def
/adds {
    /MSyms findfont 9 scalefont setfont
    2 -2 rmoveto (f) show -1 2 rmoveto 
    /Helvetica findfont 12 scalefont setfont 
    0 -3 rmoveto show 0 3 rmoveto } def
/addf {
    /MSyms findfont 12 scalefont setfont
    2 -4 rmoveto (s) show -1 4 rmoveto 
    /Helvetica findfont 12 scalefont setfont 
    0 -3 rmoveto show 0 3 rmoveto } def
/maj7 {
    /Symbol findfont 15 scalefont setfont 
    0 -2 rmoveto (D) show 0 2 rmoveto } def
/root {
    /Helvetica findfont 16 scalefont setfont
    show } def
/slash {
    /Helvetica findfont 16 scalefont setfont
    (/) show } def
/susp {
    /Helvetica findfont 12 scalefont setfont
    0 -3 rmoveto (sus) show show 0 3 rmoveto } def
/bar {
    1 setlinewidth
    currentpoint 0 -3 rmoveto 0 16 rlineto stroke moveto } def
/same1 {
    /MSyms findfont 10 scalefont setfont
    (L) dup stringwidth pop 2 div neg 0 rmoveto show } def
/rest {
    /Helvetica findfont 16 scalefont setfont
    (\261) show } def
/resth {
    /MSyms findfont 16 scalefont setfont
    (R) show } def
/ta {
    /Helvetica findfont 14 scalefont setfont
    (T.A.) show	} def
/TF {
    /Helvetica findfont 16 scalefont setfont } def
/SF {
    /Helvetica findfont 12 scalefont setfont } def
end
%%EndProcSet
%%BeginProcSet: Grid 0 0
% Routines for the drawing of chords.
/griddict 10 dict def
griddict begin
  /gridscale $std_gridscale def
  /gridwidth gridscale 5 mul def
  /gridheight gridscale 4 mul def
  /half-incr gridscale 2 div def
  /dot-size gridscale 0.35 mul def
  /displ-font /Times-Roman findfont gridscale 1.25 mul scalefont def

  /grid {				% -- grid --
    gsave currentpoint
    6 
    { 0 gridheight rlineto gridscale gridscale gridwidth sub rmoveto }
    repeat
    moveto
    5 
    { gridwidth 0 rlineto 0 gridwidth sub gridscale rmoveto }
    repeat
    stroke grestore
  } def

  /dot {				% string fret dot --
    gsave
    exch 6 exch sub gridscale mul	% str fret -> fret y
    exch dup 5 exch abs sub gridscale mul half-incr sub	% fret y -> y fret x 
    exch 3 1 roll rmoveto

    % It is tempting to use the more enhanced format (that places o
    % and x above the grid) but there is a chord caption.
    % fret {...} --
    -1 ne
    { currentpoint dot-size 0 360 arc fill }
    { gsave
      gridwidth 20 div
	    dup neg dup rmoveto
	    dup dup rlineto 
	    dup dup rlineto
	    dup neg dup rmoveto
	    dup dup neg exch rmoveto
	    dup dup neg rlineto
	        dup neg rlineto
      gridwidth 50 div setlinewidth stroke
      grestore
    } ifelse
    grestore
  } def	
end
tabdict begin
/dots {				% e a d g b e offset dots --
    griddict begin
    gsave
    1 setlinewidth
    0 setgray

    grid

    % Chord offset, if greater than 1.
    % offset {...} --
    dup () ne
    { gsave
      half-incr neg gridheight gridscale sub rmoveto
      displ-font setfont 
      dup stringwidth pop neg half-incr rmoveto show grestore 
    }
    { pop }
    ifelse

    1 1 6
    {	% fret string {...} --
	exch dup
	0 ne 
	{ dot }
	{ pop pop }
	ifelse
    }
    for
    end
} def
end
%%EndProcSet
%%EndProlog
%%BeginFont: MSyms
systemdict/currentpacking known{/SavPak currentpacking def true setpacking}if
userdict/AltRT6 known{{currentfile(   )readstring{(%%%)eq{exit}if}{pop}ifelse}loop}if
userdict begin/AltRT6 39 dict def AltRT6 begin/NL 0 def/B{bind def}bind def
/Cache{NL 0 eq{setcachedevice}{6{pop}repeat}ifelse 0 0 moveto}B
/SetWid{NL 0 eq{0 setcharwidth setgray}{pop setgray}ifelse 0 0 moveto}B
/ShowInt{/NL NL 1 add store BC2 grestore/NL NL 1 sub store}B
/charStr(.)def/Strk 0 def/Sstrk{/Strk 1 store}B
/Cfill{PaintType 0 eq{Strk 0 eq{exec}{gsave exec grestore
currentgray 0 ne{0 setgray}if stroke}ifelse}{pop stroke}ifelse}B
/Fill{{fill}Cfill}def/Eofill{{eofill}Cfill}def/Cp{closepath 0 0 moveto}def
/ShowExt{EFN exch get findfont setfont matrix currentmatrix exch
InvMtx concat 0 0 moveto charStr 0 3 -1 roll put PaintType 0 ne Strk 0 ne
or currentgray 0 ne or{charStr false charpath setmatrix Fill}
{charStr show pop}ifelse grestore}B/stringtype{{UCS}forall}B
/arraytype/exec load def/packedarraytype/exec load def
/BuildChar{AltRT6 begin exch begin BC2 end end}B
/BC2{save exch StrokeWidth setlinewidth/Strk 0 store
Encoding exch get dup CharDefs exch known not{pop/.notdef}if
CharDefs exch get newpath dup type exec restore}B 
/UVec[{rmoveto}{rlineto}{rcurveto}{ShowExt}{]concat}{Cache}{setlinewidth}
{ShowInt}{setlinecap}{setlinejoin}{gsave}{[}{Fill}{Eofill}{stroke}{SetWid}
{100 mul add}{100 mul}{100 div}{Cp}{Sstrk}{setgray}]def
/UCS{dup 200 lt{100 sub}{dup 233 lt{216 sub 100 mul add}
{233 sub UVec exch get exec}ifelse}ifelse}B
/CD{/NF exch def{exch dup/FID ne{exch NF 3 1 roll put}  
{pop pop}ifelse}forall NF}B
/MN{1 index length/Len exch def dup length Len add string dup 
Len 4 -1 roll putinterval dup 0 4 -1 roll putinterval}B
/RC{(|______)anchorsearch {1 index MN cvn/NewN exch def cvn
findfont dup maxlength dict CD dup/FontName NewN put dup
/Encoding MacVec put NewN exch definefont pop}{pop}ifelse}B
/RF{dup cvn FontDirectory exch known{pop}{RC}ifelse}B
/MacVec 256 array def MacVec 0 /Helvetica findfont
/Encoding get 0 128 getinterval putinterval MacVec 127 /DEL put
MacVec 16#27 /quotesingle put  MacVec 16#60 /grave put/NUL/SOH/STX/ETX
/EOT/ENQ/ACK/BEL/BS/HT/LF/VT/FF/CR/SO/SI/DLE/DC1/DC2/DC3/DC4/NAK/SYN
/ETB/CAN/EM/SUB/ESC/FS/GS/RS/US MacVec 0 32 getinterval astore pop
/Adieresis/Aring/Ccedilla/Eacute/Ntilde/Odieresis/Udieresis/aacute
/agrave/acircumflex/adieresis/atilde/aring/ccedilla/eacute/egrave
/ecircumflex/edieresis/iacute/igrave/icircumflex/idieresis/ntilde/oacute
/ograve/ocircumflex/odieresis/otilde/uacute/ugrave/ucircumflex/udieresis
/dagger/degree/cent/sterling/section/bullet/paragraph/germandbls
/register/copyright/trademark/acute/dieresis/notequal/AE/Oslash
/infinity/plusminus/lessequal/greaterequal/yen/mu/partialdiff/summation
/product/pi/integral/ordfeminine/ordmasculine/Omega/ae/oslash 
/questiondown/exclamdown/logicalnot/radical/florin/approxequal/Delta/guillemotleft
/guillemotright/ellipsis/nbspace/Agrave/Atilde/Otilde/OE/oe
/endash/emdash/quotedblleft/quotedblright/quoteleft/quoteright/divide/lozenge
/ydieresis/Ydieresis/fraction/currency/guilsinglleft/guilsinglright/fi/fl
/daggerdbl/periodcentered/quotesinglbase/quotedblbase
/perthousand/Acircumflex/Ecircumflex/Aacute
/Edieresis/Egrave/Iacute/Icircumflex/Idieresis/Igrave/Oacute/Ocircumflex
/apple/Ograve/Uacute/Ucircumflex/Ugrave/dotlessi/circumflex/tilde
/macron/breve/dotaccent/ring/cedilla/hungarumlaut/ogonek/caron
MacVec 128 128 getinterval astore pop end end
/$MSyms 19 dict def $MSyms begin/PaintType 0 def/FontType 3 def
/StrokeWidth 0 def/FontBBox[-30 -60 296 185]def %/UniqueID 5449203 def
/FontMatrix[0.008333 0 0 0.008333 0 0]def/InvMtx[120 0 0 120 0 0]def
/CharDefs 7 dict def/FontName (MSyms) def
/BuildChar{AltRT6/BuildChar get exec}def
/FontInfo 3 dict def FontInfo begin
/UnderlinePosition -20 def/UnderlineThickness 20 def end
/Encoding AltRT6/MacVec get def CharDefs begin/.notdef{500 0 setcharwidth} def
/at<A0645EA79171D9EE78ADE94E644E866486EB7A647A426442EBFC786ED9E94A644A3C
643CEB7E647E8C648CEBFCF5>def 
/L<96D964525E8BD96AD9EE6464E98064EAC164D9EA4864EAFC75D973E95E5D4D5E4968
EB5F70677A7578EB766174536E4CEBFC83A5E95E5D4E5E4A68EB5F7167787478EB746374
536E4CEBFCF5>def 
/R<B4645C879F84D9EE758CE96A64EA7CA7EA686FEA666A6063585FEB6062545D5865EB
676A61715971EB5B635762555AEB625C6A557155EB696468627365EB6A6571697167EBFC
F5>def 
/asciicircum<A0645E979281D9EE78ADE94E644E866486EB7A647A426442EBFC786ED9
E94A644A3C643CEB7E647E8C648CEBFC887DD9E9401EEA6864EA88AAEAFCF5>def 
/d<A0646B489376D9EE706FD9E96463D7EA7D6CEA643DEA6964EA6465D9EA4B5CEA648B
EAFC759CE9786BEA6447EA505DEAFCF5>def 
/f<B4645B3EA980D9EE7346E9648CD9EA6964EA643CD7EAFC8C50E9648CD9EA6964EA64
3CD7EAFC6469E96473EAA078EA6455EAFC6496E96473EAA078EA6455EAFCF5>def 
/s<A0645E698F7FD9EE797FE9726E7D7B6D94EB616A536A4F64EB605FEA6497EA5F64EA
645AD7EAFC69A4E96A67EA6D687060705BEB655162515C4AEB5A59EAFCF5>def 
end/EFN[]def
end systemdict/currentpacking known{SavPak setpacking}if
/MSyms $MSyms definefont pop
/MSyms findfont/EFN get AltRT6 begin{RF}forall end
%%EndFont
%%BeginSetup
%%PaperSize: A4
%%EndSetup
