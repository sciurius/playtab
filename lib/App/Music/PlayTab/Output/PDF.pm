#! perl

# Author          : Johan Vromans
# Created On      : Tue Apr 15 11:02:34 2014
# Last Modified By: Johan Vromans
# Last Modified On: Sat Apr 19 23:02:53 2014
# Update Count    : 493
# Status          : Unknown, Use with caution!

use utf8;

package App::Music::PlayTab::Output::PDF;

use strict;
use warnings;

our $VERSION = "0.001";

# Globals.

my $ps =
  { papersize     => [ 595, 840 ],	# A4, portrait
    marginleft    => 50,
    margintop     => 40,
    marginbottom  => 50,
    marginright   => 45,
    lineheight    => 15,
    fonts         => {
		      title   => { name => 'Helvetica',
				   file => $ENV{HOME}.'/.fonts/ArialMT.ttf',
				   size => 16 },
		      subtitle=> { name => 'Helvetica',
				   file => $ENV{HOME}.'/.fonts/ArialMT.ttf',
				   size => 12 },
		      chord   => { file => 'Helvetica',
				   file => $ENV{HOME}.'/.fonts/ArialMT.ttf',
				   size => 17 },
		      barno   => { file => 'Helvetica',
				   file => $ENV{HOME}.'/.fonts/ArialMT.ttf',
				   size => 8 },
		      msyms   => { file => $ENV{HOME}.'/.fonts/MSyms.ttf',
				   size => 15 },
		     },
  };

my $f_chord = $ps->{fonts}->{chord};
my $f_msyms = $ps->{fonts}->{msyms};

# Low level PDF api.
my $pr;

# Initial default values.
my $std_width	   =  30;
my $std_height	   = -15;
my $std_margin	   =  40;

# Position control.
my $xd = 0;			# step (in bar lines)
my $yd = 0;			# vertical space between lines
my $md = 0;			# additional left margin
my $x;				# actual x pos
my $y;				# actual y pos

my $barno;
my $std_gridscale = 8;

################ API Functions ################

# Object creation.
sub new {
    bless { }, shift;
}

# New page, and init the backend if needed.
sub setup {
    my ( $self, $args, $title ) = @_;
    unless ( $pr ) {
	$pr = PDFWriter->new;

	my @tm = gmtime(time);
	$pr->info( Title => "A nicely formatted play sheet",
		   Creator => "PlayTab $App::Music::PlayTab::VERSION",
		   CreationDate =>
		   sprintf("D:%04d%02d%02d%02d%02d%02d+00'00'",
			   1900+$tm[5], 1+$tm[4], @tm[3,2,1,0]),
		 );

	$xd = $std_width;
	$yd = $std_height;
	$md = $std_margin;
    }
}

sub setuppage {
    my ( $self, $title, $stitles ) = @_;
    $self->pdf_page( 1, $title, $stitles );
    undef $barno;
}

sub finish {
    my $self = shift;
    return unless $pr;
    $self->{fh}->print( $pr->finish );
    undef $pr;
}

# New print line.
sub setupline {
    my ( $self, $line ) = @_;
    $xd     = $line->{width} || 0;
    $yd     = $line->{height};
    $md     = $line->{margin} || 0;
    $barno  = $line->{barno};
}

sub bar {
    my ( $self, $first ) = @_;
    $self->checkvspace;
    $pr->vline( $x + $md, $y + 13, 16 );
    $pr->rtext( $x + $md - 2, $y + 9, $barno, $ps->{fonts}->{barno} )
      if $first && defined($barno);
    $x += 4;
}

sub chord {
    my ( $self, $chord ) = @_;
    if ( ref($chord) =~ /::/ ) {
	my $save_x = $x;
	my $save_y = $y;
	$chord->render;
	$x = $save_x + $xd;
	$y = $save_y;
	$self->{_prev_chord} = $chord;
    }
    elsif ( ref($chord) eq 'ARRAY' ) {
	my $fun = "render__" . shift(@$chord);
	$self->$fun( @$chord );
    }
    else {
	my $fun = "render__$chord";
	$self->$fun;
    }
}

sub newline {
    my ( $self, $xtra ) = @_;
    $x = $ps->{marginleft};
    $y += $yd;
    $y += ($xtra-1)*$yd if defined $xtra;
}

sub text {
    my ( $self, $text, $xxmd, $font ) = @_;
    $font ||= $ps->{fonts}->{subtitle};
    $xxmd ||= 0;
    $self->checkvspace;
    $pr->text( $x + $xxmd, $y, $text, $font );
}

sub postfix {
    my ( $self, $text ) = @_;
    $x += 4;
    $self->text( $text, $md );
}

use constant GRIDSTEP => 8;

sub grids {
    my ( $self, $grids ) = @_;

    my $n = int( ( 570 - $md - 60 ) / ( 10 * GRIDSTEP ) );

    my $i = 0;
    foreach my $ch ( @$grids ) {
	$self->render_grid($ch);
	if ( ++$i >= $n ) {
	    $self->newline(4);
	    $i = 0;
	}
	else {
	    $x += 10 * GRIDSTEP;
	}
    }
    $self->newline(3);
}

################ Other Render Functions ################

use constant MS_REST    => "\x{002b}";
use constant MS_REPT    => "\x{0024}";

sub render__again {
    my ( $self ) = @_;
    $self->chord( $self->{_prev_chord} );
}

sub render__space {
    my ( $self ) = @_;
    $x += $xd;
}

sub render__rest {
    my $self = shift;
    $pr->msym( $x + $md, $y, MS_REST, 20 );
    $x += $xd;
}

sub render__same {
    # Whole bar(s) repeat.
    my ( $self, $wh, $xs ) = @_;
    # Currently, $wh will always be 1 (single bar repeat).
    $pr->ctext( $x + $md + ($xs * $xd) / 2, $y + 3, MS_REPT, $f_msyms, 25 );
    $x += $xs * $xd;
}

sub render__hmore {
    $x += 4;
}

sub render__hless {
    $x -= 4;
}

sub render_grid {
    my ( $self, $grid ) = @_;

    my @c = @$grid;
    my $chord = shift(@c);
    my $save_x = $x;
    my $save_y = $y;
    $y += 0;
    $x += 28;
    if ( $chord =~ /::/ ) {
	$x -= $chord->width($self) / 2;
	$chord->render;
    }
    else {
	$pr->ctext( $x, $y, $chord, $f_chord );
    }
    $x = $save_x;
    $y = $save_y;

    # Fretboard.
    my $c = shift(@c);
    $pr->fretboard( $x + $md + 8, $y - 5,
		    5 * GRIDSTEP, 4 * GRIDSTEP,
		    $c, \@c );
}

################ Page managemant ################

my $pdf_pages = 0;		# physcial page number
my $pdf_page  = 1;		# logical page number

sub pdf_page {
    my ( $self, $first, $title, $stitles ) = @_;

    # Physical newpage, if needed.
    $pr->newpage if $pdf_pages++;

    # (Re)set coordinates and page number.
    $x = $ps->{marginleft};
    $y = $ps->{papersize}->[1] - $ps->{margintop};
    $pdf_page = $first ? 1 : $pdf_page+1;

    # Print title header.
    $pr->text( $x, $y, $self->{title} = $title, $ps->{fonts}->{title} );

    # Add page number, if not first (or only) page.
    if ( $pdf_page > 1 ) {
	$pr->rtext( $ps->{papersize}->[0] - $ps->{marginright}, $y,
		    "Page $pdf_page",
		    $ps->{fonts}->{subtitle} );
    }
    $self->newline;

    # Add subtitles, if any,
    foreach ( @$stitles ) {
	$pr->text( $x, $y, $_, $ps->{fonts}->{subtitle} );
	$self->newline;
    }

    # And finally some vertical space.
    $self->newline(2);
}

sub checkvspace {
    my ( $self ) = @_;

    # Check if this still fits.
    return if $y >= $ps->{marginbottom};

    # Otherwise, new page.
    $self->pdf_page( 0, $self->{title}, [] );
}

################  App::Music::PlayTab::Note ################

package App::Music::PlayTab::Note;

# Glyph mappings of the MSyms font.
use constant MS_SHARP    => "\x{0021}";
use constant MS_FLAT     => "\x{0022}";
use constant MS_NATURAL  => "\x{0023}";

sub render {
    my ($self) = @_;
    my $name = $self->name;

    if ( $name =~ /(.)b/ ) {
	my $width = $pr->strwidth( $1, $f_chord);
	$pr->text( $x + $md, $y, $1, $f_chord );
	$pr->msym( $x + $md + $width + 1, $y + 3, MS_FLAT, 25 );
    }
    elsif ( $name =~ /(.)#/ ) {
	my $width = $pr->strwidth( $1, $f_chord);
	$pr->text( $x + $md, $y, $1, $f_chord );
	$pr->msym( $x + $md + $width + 1, $y + 3, MS_SHARP, 25 );
    }
    else {
	$pr->text( $x + $md, $y, $name, $f_chord );
    }
}

my $chord_small;
my $msym_small;

sub render_small {
    my ($self) = @_;
    my $name = $self->name;

    $chord_small ||= 0.7 * $ps->{fonts}->{chord}->{size};
    $msym_small  ||= 0.7 * 25;
    my $width;

    if ( $name =~ /(.)b/ ) {
	$width = $pr->strwidth( $1, $f_chord, $chord_small );
	$pr->text( $x + $md, $y, $1, $f_chord, $chord_small );
	$pr->msym( $x + $md + $width + 1, $y + 3, MS_FLAT, $msym_small );
	$width += 1 + $pr->msymwidth( MS_FLAT, $msym_small );
    }
    elsif ( $name =~ /(.)#/ ) {
	$width = $pr->strwidth( $1, $f_chord, $chord_small );
	$pr->text( $x + $md, $y, $1, $f_chord, $chord_small );
	$pr->msym( $x + $md + $width + 1, $y + 3, MS_SHARP, $msym_small );
	$width += 1 + $pr->msymwidth( MS_FLAT, $msym_small );
    }
    else {
	$width = $pr->strwidth( $name, $f_chord, $chord_small );
	$pr->text( $x + $md, $y, $name, $f_chord, $chord_small );
    }

    $width;
}

sub width {
    my ($self) = @_;
    my $name = $self->name;
    my $width = $pr->strwidth($name, $f_chord);

    if ( $name =~ /(.)b/ ) {
	return $pr->strwidth( $1, $f_chord)
	  + 1 + $pr->msymwidth( MS_FLAT );
    }
    if ( $name =~ /(.)#/ ) {
	return $pr->strwidth( $1, $f_chord)
	  + 1 + $pr->msymwidth( MS_SHARP );
    }

    return $pr->strwidth( $name, $f_chord );
}

################ App::Music::PlayTab::Chord ################

package App::Music::PlayTab::Chord;

# Glyph mappings of the MSyms font.
use constant MS_SHARP    => "\x{0021}";
use constant MS_FLAT     => "\x{0022}";
use constant MS_DIM      => "\x{0027}";
use constant MS_HDIM     => "\x{0028}";
use constant MS_AUG      => "\x{0029}";
use constant MS_MAJOR7   => "\x{002a}";
use constant MS_MINOR    => "\x{002b}";

sub render {
    my ($self) = @_;

    my $width = $self->{key}->width;
    $self->{key}->render;

    my $res = "";
    my @v = @{$self->{vec}};
    my $v = "@v ";
    shift (@v);

    if ( $v =~ s/^0 (2 )?4 (6|7|8) / / ) {
	if ( $2 == 8 ) {
	    $pr->msym( $x + $md + $width + 1, $y + 8, MS_AUG );
	}
	$v = ' 6' . $v if $2 == 6;
	$v = ' 2' . $v if defined $1;
    }
    elsif ( $v =~ s/^0 3 6 9 / / ) {
	$pr->msym( $x + $md + $width + 1, $y + 8, MS_DIM );
    }
    elsif ( $v =~ s/^0 (2 )?3 (6|7|8) / / ) {
	if ( $2 == 6 ) {
	    if ( $v =~ s/^ 10 // ) {
		$pr->msym( $x + $md + $width + 1, $y + 8, MS_HDIM );
	    }
	    else {
		$pr->msym( $x + $md + $width + 1, $y + 8, MS_DIM );
	    }
	}
	else {
	    $pr->msym( $x + $md + $width + 1, $y + 8, MS_MINOR );
	}
	$v = ' 8' . $v 	if $2 == 8;
	$v = ' 2' . $v  if defined $1;
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
	$pr->text( $x + $md + $width + 0.5, $y - 3, "7", $f_chord, 12);
	$width += 0.5 + $pr->strwidth( "7", $f_chord, 12 );
    }
    elsif ( $v =~ s/^( \d| 10|) 11 / $1/ ) {
	#### TODO: Correct -2 if flat?
	$pr->msym( $x + $md + $width + 0.5, $y - 3, MS_MAJOR7 );
	$width += 0.5 + $pr->msymwidth( MS_MAJOR7 );
    }
    if ( $v =~ s/ 5 7 / / ) {
	$pr->text( $x + $md + $width + 1, $y - 3, "sus", $f_chord, 12 );
	$width += 1 + $pr->strwidth( "sus", $f_chord, 12 );
    }
    elsif ( $v =~ s/^0 7 / / ) {
	$pr->text( $x + $md + $width + 1, $y - 3, "sus2", $f_chord, 12 );
	$width += 1 + $pr->strwidth( "sus2", $f_chord, 12 );
    }
    elsif ( $v =~ s/^0 4 / / ) {
	$pr->text( $x + $md + $width + 1, $y - 3, "no5", $f_chord, 12 );
	$width += 1 + $pr->strwidth( "no5", $f_chord, 12 );
    }

    my $addn = sub {
	my ( $text ) = @_;
	$pr->text( $x + $md + $width + 0.5, $y - 3, $text, $f_chord, 12);
	$width += 0.5 + $pr->strwidth( $text, $f_chord, 12 );
    };
    my $addf = sub {
	my ( $text ) = @_;
	$pr->msym( $x + $md + $width + 0.5, $y - 3, MS_FLAT, 18);
	$width += 0.5 + $pr->msymwidth( MS_FLAT, 18 );
	$pr->text( $x + $md + $width + 0.5, $y - 3, $text, $f_chord, 12);
	$width += 0.5 + $pr->strwidth( $text, $f_chord, 12 )
    };
    my $adds = sub {
	my ( $text ) = @_;
	$pr->msym( $x + $md + $width + 0.5, $y - 3, MS_SHARP, 18);
	$width += 0.5 + $pr->msymwidth( MS_SHARP, 18 );
	$pr->text( $x + $md + $width + 0.5, $y - 3, $text, $f_chord, 12);
	$width += 0.5 + $pr->strwidth( $text, $f_chord, 12 );
    };

    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	my $op =
	  ( [ $addn,  1 ], [ $addf,  2 ], [ $addn,  2 ], [ $addf,  3 ],
	    [ $addn,  3 ], [ $addn,  4 ], [ $addf,  5 ], [ $addn,  5 ],
	    [ $adds,  5 ], [ $addn,  6 ], [ $addn,  7 ], [ $adds,  7 ],
	    [ $addn,  8 ], [ $addf,  9 ], [ $addn,  9 ], [ $adds,  9 ],
	    [ $addf, 11 ], [ $addn, 11 ], [ $adds, 11 ], [ $addn, 12 ],
	    [ $addf, 13 ], [ $addn, 13 ],
	  )[$_];

	$op->[0]->( $op->[1] ) if $op;
    }

    if ( $self->{high} ) {
	#### TODO
	$y += 5;
	$x += $width;
	foreach ( @{$self->{bass}} ) {
	    $pr->text( $x + $md + 2, $y, "\\", $f_chord );
	    $x += 7;
	    $x += $_->{key}->render_small;
	    $y += 4;
	}
    }

    if ( $self->{bass} ) {
	$y -= 5;
	$x += $width;
	foreach ( @{$self->{bass}} ) {
	    $pr->text( $x + $md + 2, $y, "/", $f_chord );
	    $x += 7;
	    $x += $_->{key}->render_small;
	    $y -= 4;
	}
    }

}

sub width {
    my ($self) = @_;

    my $width = $self->{key}->width;

    my $res;
    my @v = @{$self->{vec}};
    my $v = "@v ";
    shift (@v);

    if ( $v =~ s/^0 (2 )?4 (6|7|8) / / ) {
	if ( $2 == 8 ) {
	    $width += $pr->msymwidth( MS_AUG );
	}
	$v = ' 6' . $v if $2 == 6;
	$v = ' 2' . $v if defined $1;
    }
    elsif ( $v =~ s/^0 3 6 9 / / ) {
	$width += $pr->msymwidth( MS_DIM );
    }
    elsif ( $v =~ s/^0 (2 )?3 (6|7|8) / / ) {
	if ( $2 == 6 ) {
	    if ( $v =~ s/^ 10 // ) {
		$width += $pr->msymwidth( MS_HDIM );
	    }
	    else {
		$width += $pr->msymwidth( MS_DIM );
	    }
	}
	else {
	    $width += $pr->msymwidth( MS_MINOR );
	}
	$v = ' 8' . $v 	if $2 == 8;
	$v = ' 2' . $v  if defined $1;
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
	$width += $pr->strwidth( "7", $f_chord, 12);
    }
    elsif ( $v =~ s/^( \d| 10|) 11 / $1/ ) {
	$width += $pr->msymwidth( MS_MAJOR7 );
    }
    if ( $v =~ s/ 5 7 / / ) {
	$width += 1 + $pr->strwidth( "sus", $f_chord, 12 );
    }
    elsif ( $v =~ s/^0 7 / / ) {
	$width += 1 + $pr->strwidth( "sus2", $f_chord, 12 );
    }
    elsif ( $v =~ s/^0 4 / / ) {
	$width += 1 + $pr->strwidth( "no5", $f_chord, 12 );
    }

    my $addn = sub {
	my ( $text ) = @_;
	$width += 0.5 + $pr->strwidth( $text, $f_chord, 12 );
    };
    my $addf = sub {
	my ( $text ) = @_;
	$width += 0.5 + $pr->msymwidth( MS_FLAT, 18 );
	$width += 0.5 + $pr->strwidth( $text, $f_chord, 12 )
    };
    my $adds = sub {
	my ( $text ) = @_;
	$width += 0.5 + $pr->msymwidth( MS_SHARP, 18 );
	$width += 0.5 + $pr->strwidth( $text, $f_chord, 12 );
    };

    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	my $op =
	  ( [ $addn,  1 ], [ $addf,  2 ], [ $addn,  2 ], [ $addf,  3 ],
	    [ $addn,  3 ], [ $addn,  4 ], [ $addf,  5 ], [ $addn,  5 ],
	    [ $adds,  5 ], [ $addn,  6 ], [ $addn,  7 ], [ $adds,  7 ],
	    [ $addn,  8 ], [ $addf,  9 ], [ $addn,  9 ], [ $adds,  9 ],
	    [ $addf, 11 ], [ $addn, 11 ], [ $adds, 11 ], [ $addn, 12 ],
	    [ $addf, 13 ], [ $addn, 13 ],
	  )[$_];

	$op->[0]->( $op->[1] ) if $op;
    }

    if ( $self->{high} ) {
	foreach ( @{$self->{high}} ) {
	    $pr->text( $x + $md + 2, $y, "\\", $f_chord );
	    $width += 7;
	    $width += $_->{key}->width * 0.7;
	}
    }

    if ( $self->{bass} ) {
	foreach ( @{$self->{bass}} ) {
	    $pr->text( $x + $md + 2, $y, "/", $f_chord );
	    $width += 7;
	    $width += $_->{key}->width * 0.7;
	}
    }

    return $width;
}

################ PDF Writer (low level PDF API) ################

package PDFWriter;

use strict;
use warnings;
use PDF::API2;
use Encode;

my %fonts;

# Glyph mappings of the MSyms font.
use constant MS_FBFILLED => "\x{002e}";
use constant MS_FBX      => "\x{002f}";
use constant MS_FBOPEN   => "\x{0030}";

sub new {
    my ( $pkg ) = @_;
    my $self = bless { }, $pkg;
    $self->{pdf} = PDF::API2->new;
    $self->newpage;
    $self;
}

sub info {
    my ( $self, %info ) = @_;
    $self->{pdf}->info( %info );
}

sub text {
    splice( @_, 1, 0, -1 );
    goto &_text;
}
sub rtext {
    splice( @_, 1, 0, 1 );
    goto &_text;
}
sub ctext {
    splice( @_, 1, 0, 0 );
    goto &_text;
}

sub msym {
    my ( $self, $x, $y, $sym, $size ) = @_;
    my $font = $f_msyms;
    $size ||= $font->{size};
    $self->setfont($font, $size);
    $self->{pdftext}->translate( $x, $y );
    $self->{pdftext}->text($sym);
}

my %msymwidth;

sub msymwidth {
    my ( $self, $sym, $size ) = @_;
    my $key = $sym;
    $key .= "\0$size" if defined $size;
    $msymwidth{$key} ||= do {
	my $font = $f_msyms;
	$size ||= $font->{size};
	$self->setfont($font, $size);
	$self->{pdftext}->advancewidth($sym);
    };
}

sub _text {
    my ( $self, $align, $x, $y, $text, $font, $size ) = @_;

    $font ||= $self->{font};
    $size ||= $font->{size};
#    $text = encode( "cp1250", $text ) unless $font->{file}; # #### TODO ???
    $text =~ s/'/’/g;

    if ( 1 ) {
	warn( "TEXT: ",
	      '"', $text, '" [ ',
	      defined $x ? "x=$x " : "",
	      defined $y ? "y=$y " : "",
	      $font->{name} ? "font=".($font->{name})." " : "",
	      $size ? "size=$size " : "",
	      "]\n" );
    }

    $self->setfont($font, $size);

    $self->{pdftext}->translate( $x, $y );
    if ( $align > 0 ) {
	$self->{pdftext}->text_right($text);
    }
    elsif ( $align < 0 ) {
	$self->{pdftext}->text($text);
    }
    else {
	$self->{pdftext}->text_center($text);
    }
}

sub setfont {
    my ( $self, $font, $size ) = @_;
    $self->{font} = $font;
    $self->{fontsize} = $size ||= $font->{size};
    $self->{pdftext}->font( $self->_getfont($font), $size );
}

sub _getfont {
    my ( $self, $font ) = @_;
    $self->{font} = $font;
    if ( $font->{file} ) {
	return $fonts{$font->{file}} ||=
	  $self->{pdf}->ttfont( $font->{file}, -dokern => 1 );
    }
    else {
	return $fonts{$font->{name}} ||=
	  $self->{pdf}->corefont( $font->{name} );
    }
}

my %strwidth;

sub strwidth {
    my ( $self, $text, $font, $size ) = @_;
    $font ||= $self->{font};
    $size ||= $font->{size};
    my $key = "$text\0$font\0$size";
    $strwidth{$key} ||= do {
	$self->setfont( $font, $size );
	$self->{pdftext}->advancewidth($text);
    };
}

sub newpage {
    my ( $self ) = @_;
    #$self->{pdftext}->textend if $self->{pdftext};
    $self->{pdfpage} = $self->{pdf}->page;
    $self->{pdfpage}->mediabox('A4');
    $self->{pdftext} = $self->{pdfpage}->text;
    $self->{pdfgfx}  = $self->{pdfpage}->gfx;
    $self->{pdfgfx}->linewidth(1);
    $self->{pdfgfx}->strokecolor("#000000");
}

sub vline {
    my ( $self, $x, $y, $height ) = @_;
    $self->{pdfgfx}->move( $x, $y );
    $self->{pdfgfx}->vline( $y - $height );
    $self->{pdfgfx}->stroke;
}

sub hline {
    my ( $self, $x, $y, $width ) = @_;
    $self->{pdfgfx}->move( $x, $y );
    $self->{pdfgfx}->hline( $x + $width );
    $self->{pdfgfx}->stroke;
}

my @Rom = qw(I II III IV V VI VII VIII IX X XI XII
	     XIII XIV XV XVI XVII XVIII XIX XX XXI XXII XXIII XXIV );

sub fretboard {
    my ( $self, $x, $y, $width, $height, $start, $dots ) = @_;
    my $cw = $width / 5;
    my $ch = $height / 4;

    $self->{pdfgfx}->rectxy( $x, $y, $x + $width, $y - $height );
    $self->{pdfgfx}->stroke;

    for my $i  ( 1 .. 4 ) {
	$self->vline( $x + $i*$cw, $y, 4*$ch );
	for my $j ( 1 .. 3 ) {
	    $self->hline( $x, $y - $j*$ch, 5*$cw );
	}
    }

    if ( $start ) {
	my $r = $Rom[$start-1];
	# Map to MSyms glyphs.
	$r =~ tr/IVXLMDC/1234567/;
	$self->rtext( $x - 3, $y - 4, $r, $f_msyms );
    }
    else {
	$self->hline( $x, $y - 0.7, 5*$cw );
    }

    return unless $dots;

    $x -= $cw / 2;
    $y += $ch / 2;
    foreach my $dot ( @$dots ) {
	if ( $dot < 0 ) {
	    $self->msym( $x + 1.8, $y - $ch - 2.5, MS_FBX, 30 );
	}
	elsif ( $dot > 0 ) {
	    $self->msym( $x + 1, $y - $ch*$dot - 2.7, MS_FBFILLED, 40 );
	}
	$x += $ch;
    }

}

sub add {
    my ( $self, @text ) = @_;
#    prAdd( "@text" );
}

sub finish {
    my $self = shift;
    $self->{pdf}->stringify;
}

1;

__END__

=head1 NAME

App::Music::PlayTab::Output::PDF - PDF output.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.

=head1 MSYMS FONT LAYOUT

  !  Sharp		Sharp Sign
  "  Flat		Flat Sign
  #  Natural		Natural Sign
  $  Repeat1Bar		1 Bar repeat
  %  Repeat2Bars	2 Bars Repeat
  &  Repeat4Bars	4 Bars Repeat
  '  ChordDim		Diminished Chord
  (  ChordHalfDim	Half Diminished Chord
  )  ChordAug		Augmented Chord
  *  ChordMajor7	Major 7 Chord
  +  ChordMinor		Minor Chord
  ,  FB6String		6-String Fretboard
  -  FB6StringNut	6-String Fretboard (at nut)
  .  FBFilled		Filled Circle (played string)
  /  FBX		Small Cross (non-played string)
  0  FB0		Small 0 (open string)
  1  RomanI		Small Cap Letter for Roman numerals
  2  RomanV		Small Cap Letter for Roman numerals
  3  RomanX		Small Cap Letter for Roman numerals
  4  RomanL		Small Cap Letter for Roman numerals
  5  RomanM		Small Cap Letter for Roman numerals
  6  RomanD		Small Cap Letter for Roman numerals
  7  RomanC		Small Cap Letter for Roman numerals
