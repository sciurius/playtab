#!/usr/local/bin/perl5
$RCS_Id = '$Id$ ';
($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
$my_version .= '*' if length('$Locker$ ') > 12;

# Calculate scales, chords, etc..

################ Options ################

&options;

################ Presets ################

&init;

################ Main ################

while ( <> ) {
    next if /^\s*#/;
    next unless /\S/;
    chop;
    s/\^\s+//;
    if ( /^T\s+/i ) {
	&print_title (1, $');
	next;
    }
    if ( /^S\s+/i ) {
	&print_title (0, $');
	next;
    }
    if ( /^W\s+([-+])?(\d+)/ ) {
	if ( defined $1 ) {
	    $xd += $1.$2;
	}
	else {
	    $xd = $2;
	}
	next;
    }
    if ( /^H\s+([-+])?(\d+)/ ) {
	if ( defined $1 ) {
	    $yd -= $1.$2;
	}
	else {
	    $yd = -$2;
	}
	next;
    }
    if ( /^=/ ) {
	&advance (1, $');
	next;
    }
    if ( /^-/ ) {
	&advance (0.5, $');
	next;
    }
    if ( /^\+/ ) {
	&advance (0, $');
	next;
    }
    
    $line = $_;
    s/\|/ | /g;
    s/\./ . /g;
    s/:/ : /g;
    $line = $_;
    @c = split (' ');
    foreach $c ( @c ) {
	if ( $c eq '|' ) {
	    &print_bar;
	    next;
	}
	elsif ( $c eq ':' ) {
	    &print_again;
	    next;
	}
	elsif ( $c eq '.' ) {
	    &print_space;
	    next;
	}
	($chord, $key, @vec) = &parse_chord ($c);
	&print_chord ($chord, $key, @vec);
    }
    &print_newline;
}

&ps_trailer if defined $did_ps_preamble;
exit 0;

################ Subroutines ################

sub print_title {
    local ($new, $title) = @_;
    &ps_preamble unless $did_ps_preamble;

    if ( $new ) {
	print STDOUT ('showpage', "\n") if $ps_pages;
	print STDOUT ('%%Page: ', ++$ps_pages. ' ', $ps_pages, "\n");
	$x = $y = $xm = 0; $xd = $std_width; $yd = $std_height;
    }
    else {
	$y -= 1.3*$yd;
    }
    &ps_move;
    print STDOUT ($new ? 'TF (' : 'SF (', $title, ') show', "\n");
    &ps_advance;
    &ps_advance;
}

sub print_chord {
    &ps_preamble unless $did_ps_preamble;
    $prev_chord = &ps_chordname;
    &ps_move;
    print STDOUT ($prev_chord, "\n");
    &ps_step;
}

sub print_again {
    &ps_preamble unless $did_ps_preamble;
    &ps_move;
    print STDOUT ($prev_chord, "\n");
    &ps_step;
}

sub print_bar {
    &ps_preamble unless $did_ps_preamble;
    &ps_move;
    print STDOUT ("bar\n");
    $x += 4;
}

sub print_newline {
    &ps_preamble unless $did_ps_preamble;
    &ps_advance;
}

sub print_space {
    &ps_step;
}

sub advance {
    local ($full, $margin) = @_;
    $x = 0;
    $y += $yd * $full;
    return unless defined $margin;
    $margin =~ s/^\s+//;
    $margin =~ s/\s$//;
    $xm = 0;
    &ps_move;
    print STDOUT ('SF (', $margin, ') show', "\n");
    $xm = $std_margin;
}

sub ps_move {
    print STDOUT ($x0+$x+$xm, ' ' , $y0+$y, ' m ');
}

sub ps_step {
    $x += $xd;
}

sub ps_advance {
    $x = 0;
    $y += $yd;
}

sub ps_preamble {
    print STDOUT <<EOD;
%!PS-Adobe-2.0
%%Pages: (atend)
%%DocumentFonts: Helvetica
%%EndComments
%%BeginProcSet: Symbols 0
/m { moveto } bind def
/dim {
    currentpoint
    /Marl findfont 18 scalefont setfont
    1 -2 rmoveto (@) show moveto } def
/hdim {
    currentpoint
    /Marl findfont 18 scalefont setfont 
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
    /Marl findfont 13 scalefont setfont
    2 0 rmoveto (f) show -1 0 rmoveto } def
/flat {
    /Marl findfont 16 scalefont setfont 
    2 -2 rmoveto (s) show -2 2 rmoveto } def
/addn {
    /Helvetica findfont 12 scalefont setfont 
    0 -3 rmoveto show 0 3 rmoveto } def
/adds {
    /Marl findfont 9 scalefont setfont
    2 -2 rmoveto (f) show -1 2 rmoveto 
    /Helvetica findfont 12 scalefont setfont 
    0 -3 rmoveto show 0 3 rmoveto } def
/addf {
    /Marl findfont 12 scalefont setfont
    2 -4 rmoveto (s) show -1 4 rmoveto 
    /Helvetica findfont 12 scalefont setfont 
    0 -3 rmoveto show 0 3 rmoveto } def
/maj7 {
    /Symbol findfont 15 scalefont setfont 
    0 -2 rmoveto (D) show 0 2 rmoveto } def
/root {
    /Helvetica findfont 16 scalefont setfont
    show } def
/susp {
    /Helvetica findfont 12 scalefont setfont
    0 -3 rmoveto (sus) show show 0 3 rmoveto } def
/bar {
    1 setlinewidth
    currentpoint 0 -3 rmoveto 0 16 rlineto stroke moveto } def
/TF {
    /Helvetica findfont 16 scalefont setfont } def
/SF {
    /Helvetica findfont 12 scalefont setfont } def
%%EndProcSet
%%EndProlog
%%BeginSetup
%%PaperSize: A4
(/home/jv/lib/psfonts/Marl.pfa)run
%%EndSetup
EOD
    $did_ps_preamble = 1;
    $x0 = 50; $y0 = 800; $xd = $std_width; $yd = $std_height;
    $x = $y = $xm = 0; $std_margin = 40;
    $ps_pages = 0;
}

sub ps_trailer {
    print STDOUT <<EOD;
showpage
%%Trailer
%%Pages: $ps_pages
%%EOF
EOD
}

sub parse_note {
    local ($note) = @_;

    # Parse note name and return internal code.
    # Side-effect: sets $use_flat if appropriate.

    # Trim.
    $note =~ s/\s+$//;

    # Get out if relative scale specifier.
    return '*' if $note eq '*';

    local ($res);
    *Notes = *SNotes;

    # Try sharp notes, e.g. Ais, C#.
    if ( $note =~ /^([a-g])(is|\#)$/i ) {
	$res = (10,0,1,3,5,6,8)[ord("\U$1")-ord('A')];
    }
    # Try flat notes, e.g. Es, Bes, Db.
    elsif ( $note =~ /^([a-g])(e?s|b)$/i ) {
	$res = (8,10,11,1,3,4,6)[ord("\U$1")-ord('A')];
	*Notes = *FNotes;
    }
    # Try plain note, e.g. A, C.
    elsif ( $note =~ /^([a-g])$/i ) {
	$res = (9,11,0,2,4,5,7)[ord("\U$1")-ord('A')];
    }
    # No more tries.
    else {
	&errout ("Unrecognized note name \"$note\"");
    }

    # Return.
    print STDERR ("=ch=> $note -> $res\n") if $opt_debug;
    $res;
}

sub parse_chord {
    local ($chord) = @_;

    $chord = "\L$chord";

    # Separate the chord key from the modifications.
    if ( $chord =~ /^[a-g*](\#|b|s|es|is)?/ ) {
	$key = $&;
	$mod = $';
	$mod = chop($key) . $mod
	    if $1 eq 's' && substr($',0,2) eq 'us';
    }
    else {
	$key = $chord;
	$mod = '';
    }

    # Parse key.
    print STDERR ("=pc=> $chord -> [$key,$mod]\n") if $opt_debug;
    $key = &parse_note ($key);

    # Encodings: a bit is set in $chflags for every note in the chord.
    # The corresponding element of $chmods is 0 (natural), -1
    # (lowered), 1 (raised) or undef (suppressed).

    local ($chflags) = '';
    local ($chmods) = (0) x 14;

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
	if ( $mod =~ /^[(). ]/ ) {	# syntactic sugar
	    $mod = $';
	    next;
	}
	if ( $mod =~ /^maj7?/ ) {	# Maj7
	    $mod = $';
	    vec($chflags,7,1) = 1;
	    $chmods[7] = 1;
	    next;
	}
	if ( $mod =~ /^(min|m)/ ) {	# Minor triad
	    $mod = $';
	    vec($chflags,3,1) = 1;
	    $chmods[3] = -1;
	    next;
	}
	if ( $mod =~ /^sus4?/ ) {	# Suspended fourth
	    $mod = $';
	    vec($chflags,4,1) = 1;	# does it?
	    undef $chmods[3];
	    $chmods[4] = 0;
	    next;
	}
	if ( $mod =~ /^aug/ ) {		# Augmented
	    $mod = $';
	    vec($chflags,5,1) = 1;
	    $chmods[5] = 1;
	    next;
	}
	if ( $mod =~ /^(o|dim)/ ) {	# Diminished
	    $mod = $';
	    vec($chflags,3,1) = 1;
	    vec($chflags,5,1) = 1;
	    $chmods[3] = -1;
	    $chmods[5] = -1;
	    next;
	}
	if ( $mod =~ /^%/ ) {	# half-diminished 7
	    $mod = $';
	    $chflags = '';
	    vec($chflags,3,1) = 1;
	    vec($chflags,5,1) = 1;
	    vec($chflags,7,1) = 1;
	    $chmods[3] = -1;
	    $chmods[5] = -1;
	    $chmods[7] = 0;
	    next;
	}
	if ( $mod =~ /^([\#b])?(5|6|7|9|10|11|13)/ ) { # addition
	    $mod = $';
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
	if ( $mod =~ /^no\s*(\d+)(st|nd|rd|st)?/ ) {
	    $mod = $';
	    vec($chflags,$1,1) = 1;
	    undef $chmods[$1];
	    next;
	}
	&errout ("Unknown chord modification: \"$mod\"");
    }

    local (@vec) = (0);
    for (1..13) {
	next unless vec($chflags,$_,1);
	next unless defined $chmods[$_];
	push (@vec, (0,0,2,4,5,7,9,10,12,14,16,17,19,21)[$_]+$chmods[$_]);
    }
    $chord = &chordname;
    print STDERR ("=pc=> $chord -> $key\[@vec]\n") if $opt_debug;
    ("\u$chord", $key, @vec);

    # TODO: maug
}

sub chordname {
    local ($res) = $Notes[$key eq '*' ? 0 : $key];
    $res =~ s/\s+$//;

    local (@v) = @vec;
    shift (@v);

    $v = "@vec ";
    print STDERR ("=cn=> $v\n") if $opt_debug;
    if ( $v =~ s/^0 4 (6|7|8) / / ) {
	$res .= $1 == 8 ? '+' : '';
	$v = ' 6' . $v if $1 == 6;
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
    $v =~ s/ 10 14 18 (21|22) / $1 /;
    $v =~ s/ 10 14 (17|18) / $1 /;
    $v =~ s/ 10 (14|15) / $1 /;
    $v =~ s/ 11 14 18 (21|22) / $1 11 /;
    $v =~ s/ 11 14 (17|18) / $1 11 /;
    $v =~ s/ 11 (14|15) / $1 11 /;
    if ( $v =~ s/ 10 / / ) {
	$res .= '7';
    }
    elsif ( $v =~ s/^( \d| 10)* 11 / $1/ ) {
	$res .= 'maj7';
    }
    print STDERR ("=cn=> $v\n") if $opt_debug;
    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	$res .= '('.('1','b2','2','b3','3','4','b5','5','#5','6','7','#7','8','b9','9','b10','b11','11','#11','12','b13','13')[$_].')';
    }
    local ($res0) = $res;
    $res =~ s/^([^\(]*[^\d])?\((\d+)\)([^\d][^\(]*)?$/$1$2$3/;
    $res =~ s/7?(6|\(6\))(9|\(9\))/6.9/;
    $res =~ s/(4|\(4\))(5|\(5\))/sus4/;
    print STDERR ("=cn=> $chord -> $res0 -> $res\n") if $opt_debug;
    $res;
}

sub ps_chordname {
    local ($res) = $Notes[$key eq '*' ? 0 : $key];
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

    local (@v) = @vec;
    shift (@v);

    $v = "@vec ";
    print STDERR ("=cn=> $v\n") if $opt_debug;
    if ( $v =~ s/^0 4 (6|7|8) / / ) {
	$res .= $1 == 8 ? 'plus ' : '';
	$v = ' 6' . $v if $1 == 6;
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
    $v =~ s/ 10 14 18 (21|22) / $1 /;
    $v =~ s/ 10 14 (17|18) / $1 /;
    $v =~ s/ 10 (14|15) / $1 /;
    $v =~ s/ 11 14 18 (21|22) / $1 11 /;
    $v =~ s/ 11 14 (17|18) / $1 11 /;
    $v =~ s/ 11 (14|15) / $1 11 /;
    if ( $v =~ s/ 10 / / ) {
	$res .= '(7) addn ';
    }
    elsif ( $v =~ s/^( \d| 10)* 11 / $1/ ) {
	$res .= 'delta ';
    }
    if ( $v =~ s/ 5 7 / / ) {
	$res .= '(4) susp ';
    }
    print STDERR ("=cn=> $v\n") if $opt_debug;
    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	$res .= ('(1) addn ','(2) addf ','(2) addn ','(3) addf ','(3) addn ',
		 '(4) addn ','(5) addf ','(5) addn ','(5) adds ','(6) addn ',
		 '(7) addn ','(7) adds ','(8) addn ','(9) addf ','(9) addn ',
		 '(10) addf ','(11) addf ','(11) addn ','(11) adds ',
		 '(12) addn ','(13) addf ','(13) addn ')[$_];
    }
    print STDERR ("=cn=> $chord -> $res\n") if $opt_debug;
    $res;
}

sub errout {
    local (@msg) = @_;
    print STDERR (join (' ', @msg), "\n",
		  "Line $.: $line\n");
}

sub init {
    # All notes, using sharps.
    @SNotes = 
	# 0    1    2    3    4    5    6    7    8    9    10   11
	('C ','C#','D ','D#','E ','F ','F#','G ','G#','A ','A#','B ');
    $notes = @SNotes;
    # All notes, using flats.
    @FNotes = 
	# 0    1    2    3    4    5    6    7    8    9    10   11
	('C ','Db','D ','Eb','E ','F ','Gb','G ','Ab','A ','Bb','B ');
    $std_width = 30;
    $std_height = -30;
}

################ Options ################

sub options {

    # Defaults...
    $opt_verbose = 0;
    $opt_debug = 0;
    $opt_trace = 0;
    $opt_all = 0;
    $opt_help = 0;
    $opt_quiet = 0;
    $opt_scale = 'Major';
    $opt_chord = 0;
    $opt_fingerboard = 0;
    $opt_ps = $opt_color = 0;
    $opt_sharp = $opt_flat = $opt_auto = 0;
    $opt_syntax = 0;
    $opt_analyze = 0;

    # Process options, if any...
    if ( $ARGV[0] =~ /^-/ ) {
	require "newgetopt.pl";

	if ( ! &NGetOpt ("all", "scale=s", "fingerboard", "chord",
			 "sharp", "flat", "auto", "syntax", "ps",
			 "color", "analyze",
			 "verbose", "help", "debug", "trace")
	    || $opt_help ) {
	    &usage;
	}
	$opt_trace = 1 if $opt_debug;
	$opt_verbose = 0 if $opt_quiet;
    }
    &syntax if $opt_syntax;
}

sub usage {
    print STDERR <<EoU;
This is Chords [$my_name $my_version]

Usage: $0 [ options ] [ notes ]

Options:
   -all		generate all scales
   -scale XXX	print this scale
   -chord 	process chords instead of scales
   -flat|sharp	use flat (or sharp) scale
   -fingerboard	show positions on guitar fingerboard
   -analyze
   -ps		output in PostScript
   -color	use color PostScript
   -verbose	verbose output
   -help	this message
   -syntax	syntax for chords and notes
EoU
    exit (1);
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
EOD
    exit (1);
}
