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

&ps_preamble;
$linetype = 0;

while ( <> ) {
    next if /^\s*#/;
    next unless /\S/;
    chop ($line = $_);

    s/\^\s+//;
    if ( /^!\s*/ ) {
	&control ($');
	next;
    }

    if ( /^\s*\[/ ) {
	while ( /^\s*\[([^]]+)\]/ ) {
	    &chord ($1);
	    $_ = $';
	}
	$linetype = 2;
	next;
    }
    elsif ( $linetype == 2 ) {
        &ps_advance;
        &ps_advance;
        &ps_advance;
        &ps_advance;
	$linetype = 0;
    }

    if ( /^\s*\|/ ) {
	&ps_advance if $linetype;
	&bar ($_);
	$linetype = 1;
	next;
    }
    elsif ( $linetype == 1 && /^[-+=]/ ) {
	&ps_advance;
	$linetype = 0;
    }
	
    # Spacing/margin notes.
    if ( /^=/ ) {
	&advance (2, $');
	$linetype = 0;
	next;
    }
    if ( /^-/ ) {
	&advance (1, $');
	$linetype = 0;
	next;
    }
    if ( /^\+/ ) {
	&advance (0, $');
	$linetype = 0;
	next;
    }

    &text ($_);
    $linetype = 0;
}

&ps_trailer;
exit 0;

################ Subroutines ################

sub print_title {
    local ($new, $title) = @_;

    if ( $new ) {
	print STDOUT ('end showpage', "\n") if $ps_pages;
	print STDOUT ('%%Page: ', ++$ps_pages. ' ', $ps_pages, "\n",
		      'tabdict begin', "\n");
	$x = $y = $xm = 0; 
	$xd = $std_width; $yd = $std_height; $md = $std_margin;
    }
    &ps_move;
    print STDOUT ($new ? 'TF (' : 'SF (', $title, ') show', "\n");
    &ps_advance;
    $on_top = 1;
    $xpose = 0;
}

sub print_chord {
    $prev_chord = &ps_chordname;
    print STDOUT ($prev_chord, "\n");
}

sub print_again {
    &ps_move;
    print STDOUT ($prev_chord, "\n");
    &ps_step;
}

sub print_bar {
    &ps_move;
    print STDOUT ("bar\n");
    $x += 4;
}

sub print_newline {
    &ps_advance;
}

sub print_space {
    &ps_step;
}

sub print_rest {
    &ps_move;
    print STDOUT ("rest\n");
    &ps_step;
}

sub print_same {
    local ($wh, $xs) = @_;
    { local ($x) = $x;
      $x += ($xs * $xd) / 2;
      &ps_move;
      print STDOUT ("same$wh\n");
    }
    $x += $xs * $xd;
}

sub advance {
    local ($full, $margin) = @_;
    unless ( &on_top ) {
	$x = 0;
	$y += $yd * $full;
    }
    return unless $margin =~ /\S/;
    $margin =~ s/^\s+//;
    $margin =~ s/\s$//;
    $xm = 0;
    &ps_move;
    print STDOUT ('SF (', $margin, ') show', "\n");
    $xm = $md;
}

sub bar {
    local ($line) = @_;
    local ($chord, $key, @vec);

    &on_top;

    $line =~ s/([|.:`'])/ $1 /g;

    local (@c) = split (' ', $line);
    while ( @c > 0 ) {
	$c = shift (@c);
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
	elsif ( $c eq '%' ) {
	    local ($xs) = 1;
	    while ( @c > 0 && $c[0] eq '.' ) {
		shift (@c);
		$xs++;
	    }
	    &print_same ('1', $xs);
	    next;
	}
	elsif ( $c eq '-' ) {
	    &print_rest;
	    next;
	}
	elsif ( $c eq '\'' ) {
	    &ps_kern (1);
	    next;
	}
	elsif ( $c eq '`' ) {
	    &ps_kern (-1);
	    next;
	}

	&ps_move;
	local (@ch) = split ('/',$c);
	while ( @ch > 1 ) {
	    $c = shift (@ch);
	    ($chord, $key, @vec) = &parse_chord ($c);
	    &print_chord ($chord, $key, @vec);
	    print STDOUT ("slash\n");
	}
	($chord, $key, @vec) = &parse_chord ($ch[0]);
	&print_chord ($chord, $key, @vec);
	&ps_step;
    }
    &print_newline;
}

sub control {
    local ($_) = @_;

    # Title.
    if ( /^t(itle)?\s+/i ) {
	&print_title (1, $');
	return;
    }

    # Subtitle(s).
    if ( /^s(ub(title)?)?\s+/i ) {
	&print_title (0, $');
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
	return;
    }

    &errout ("Unrecognized control");
}

sub chord {
    local (@l) = split(' ',$_[0]);
    local ($xpose) = 0;

    &errout ("Illegal [chord] spec, need 7 or 8 values") 
	unless @l == 8 || @l == 7;
    local ($chordname, $key, @vec) = &parse_chord (shift(@l));

    @Rom = ('', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 
	    'X', 'XI', 'XII') unless defined @Rom;

    local (@c) = ();
    local ($c) = '()';
    foreach ( @l ) {
	$_ = -1 if "\L$_" eq "x";
	if ( /^@(\d+)/ ) {
	    $c = "($Rom[$1])" if $1 > 1;
	    next;
	}
	&errout ("Illegal [chord] spec, need 6 numbers") 
	    unless /^-?\d$/ || @c == 6;
	push (@c, $_);
    }

    &on_top;
    $chordname = &ps_chordname;
    print STDOUT ('1000 1000 moveto', "\n",
		  $chordname, "\n",
		  'currentpoint pop 1000 sub 2 div', "\n");
    &ps_move;
    print STDOUT (2.5*$std_gridscale, ' exch sub 8 add 0 rmoveto ',
		  $chordname, "\n");
    &ps_move;
    print STDOUT ('8 ', -5-(4*$std_gridscale), " rmoveto @c $c dots\n");
    $x += 40 + 40;
}

sub text {
    local ($line) = @_;
    local ($xm) = 0;
    &on_top;
    &ps_move;
    print STDOUT ('SF (', $line, ') show', "\n");
    &ps_advance;
}

sub on_top {
    return 0 unless $on_top;
    $x = 0;
    $y = 4*$yd;
    $on_top = 0;
    return 1;
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

sub ps_kern {
    local ($k) = @_;
    $x += $k * 4;
}

sub ps_preamble {
    print STDOUT <<EOD;
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
    /Marl findfont 10 scalefont setfont
    (L) dup stringwidth pop 2 div neg 0 rmoveto show } def
/rest {
    /Helvetica findfont 16 scalefont setfont
    (\261) show } def
/resth {
    /Marl findfont 16 scalefont setfont
    (R) show } def
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
%%BeginSetup
%%PaperSize: A4
%%EndSetup
EOD
    $x0 = 50; $y0 = 800; $xd = $std_width; $yd = $std_height;
    $x = $y = $xm = 0;
    $ps_pages = 0;
}

sub ps_trailer {
    print STDOUT <<EOD;
end showpage
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
	last;
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
    print STDERR ("=cn=> $v\n") if $opt_debug;
    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	$res .= '('.('1','b2','2','b3','3','4','b5','5','#5','6','7','#7','8','b9','9','#9','b11','11','#11','12','b13','13')[$_].')';
    }
    local ($res0) = $res;
    $res =~ s/^([^\(]*[^\d])?\((\d+)\)([^\d][^\(]*)?$/$1$2$3/;
    $res =~ s/7?(6|\(6\))(9|\(9\))/6.9/;
    $res =~ s/(4|\(4\))(5|\(5\))/sus4/;
    print STDERR ("=cn=> $chord -> $res0 -> $res\n") if $opt_debug;
    $res;
}

sub ps_chordname {
    local ($res) = $Notes[$key eq '*' ? 0 : (($key+$xpose)%12)];
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
    print STDERR ("=cn=> $v\n") if $opt_debug;
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
    # All notes, using flats.
    @FNotes = 
	# 0    1    2    3    4    5    6    7    8    9    10   11
	('C ','Db','D ','Eb','E ','F ','Gb','G ','Ab','A ','Bb','B ');

    # Print dimensions.
    $std_width  = 30;
    $std_height = -15;
    $std_margin = 40;
    $std_gridscale = 8;
}

################ Options ################

sub options {

    # Defaults...
    $opt_verbose = $opt_quiet = 0;
    $opt_debug = 0;
    $opt_trace = 0;
    $opt_help = 0;
    $opt_syntax = 0;

    # Process options, if any...
    if ( $ARGV[0] =~ /^-/ ) {
	require "newgetopt.pl";

	if ( ! &NGetOpt ('syntax',
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

Usage: $0 [ options ] [ file ... ]

Options:
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

Other:          Meaning
--------------------------------------------------------------
.               Chord space
-               Rest
%               Repeat
/               Powerchord constructor   [D/G D/E-]
--------------------------------------------------------------

EOD
    exit (1);
}
