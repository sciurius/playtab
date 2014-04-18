#! perl

# Author          : Johan Vromans
# Created On      : Tue Apr 15 11:02:34 2014
# Last Modified By: Johan Vromans
# Last Modified On: Fri Apr 18 22:06:01 2014
# Update Count    : 405
# Status          : Unknown, Use with caution!

use utf8;

package App::Music::PlayTab::Output::PDF;

use strict;
use warnings;

our $VERSION = "0.001";

# Object management.

sub new {
    bless { init => 0 }, shift;
}

sub finish {
    my $self = shift;
    return unless $self->{init};
    $self->print_finish;
    $self->{init} = 0;
}

sub DESTROY {
    &finish;
}

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

use constant MS_REST    => "\x{002b}";
use constant MS_REPT    => "\x{0024}";

# New page, and init the backend if needed.
sub print_setup {
    my ( $self, $args, $title ) = @_;
    unless ( $self->{init}++ ) {
	$self->{pr} = PDFWriter->new( $self );

	my @tm = gmtime(time);
	$self->{pr}->info( Title => "A nicely formatted play sheet",
			   Creator => "PlayTab $App::Music::PlayTab::VERSION",
			   CreationDate =>
			   sprintf("D:%04d%02d%02d%02d%02d%02d+00'00'",
				   1900+$tm[5], 1+$tm[4], @tm[3,2,1,0]),
			 );
	$self->{ps} = page_settings();
	$xd = $std_width;
	$yd = $std_height;
	$md = $std_margin;

	binmode( STDERR, ':utf8' );
    }
}

sub print_setuppage {
    my ( $self, $title, $stitles ) = @_;
    $self->pdf_page( 1, $title, $stitles );
    undef $barno;
}

sub print_finish {
    my $self = shift;
    return unless $self->{init};
    $self->{fh}->print( $self->{pr}->finish );
    $self->{init} = 0;
}

# New print line.
sub print_setupline {
    my ( $self, $line ) = @_;
    $xd     = $line->{width} || 0;
    $yd     = $line->{height};
    $md     = $line->{margin} || 0;
    $barno  = $line->{barno};
}

sub print_title {
    my ( $self, $ttle, $text ) = @_;
    $self->{pr}->text( $text, $x, $y,
		       $ttle
		       ? $self->{ps}->{fonts}->{title}
		       : $self->{ps}->{fonts}->{subtitle} );
    $self->print_newline();
    undef $barno;
    $self->{title} = $text if $ttle;
}

sub print_subtitle {
    my ( $self, $text ) = @_;
    $self->{pr}->text( $text, $x, $y,
		       $self->{ps}->{fonts}->{subtitle} );
    $self->print_newline();
}

sub print_chord {
    my ( $self, $chord ) = @_;
    if ( ref($chord) =~ /::/ ) {
	my $save_x = $x;
	$self->pdf_chord($chord);
	$x = $save_x + $xd;
	$self->{_prev_chord} = $chord;
    }
    elsif ( ref($chord) eq 'ARRAY' ) {
	my $fun = "print_" . shift(@$chord);
	$self->$fun( @$chord );
    }
    else {
	my $fun = "print_$chord";
	$self->$fun;
    }
}

sub print_again {
    my ( $self ) = @_;
    $self->print_chord( $self->{_prev_chord} );
}

sub print_bar {
    my ( $self, $first ) = @_;
    $self->pdf_checkvspace;
    $self->{pr}->vline( $x + $md, $y + 13, 16 );
    $self->{pr}->rtext( $barno, $x + $md - 2, $y + 9,
			$self->{ps}->{fonts}->{barno} )
      if $first && defined($barno);
    $self->pdf_skip(4);
}

sub print_newline {
    my ( $self, $xtra ) = @_;
    $x = $self->{ps}->{marginleft};
    $y += $yd;
    $y += ($xtra-1)*$yd if defined $xtra;
}

sub print_space {
    my ( $self ) = @_;
    $self->pdf_step;
}

sub print_rest {
    my $self = shift;
    $self->{pr}->msym( MS_REST, $x + $md, $y, 20 );
    $self->pdf_skip( $xd );
}

sub print_same {
    my ( $self, $wh, $xs ) = @_;
    my $save_x = $x;
    $x += ($xs * $xd) / 2;
    $self->{pr}->ctext( MS_REPT, $x + $md, $y + 3,
		       $self->{ps}->{fonts}->{msyms}, 25 );
    $x = $save_x + $xs * $xd;
}

sub print_ta {
    my $self = shift;
    return;
    ps_move();
    $self->{fh}->print("ta\n");
    ps_step();
}

sub print_postfix {
    my ( $self, $text ) = @_;
    $self->pdf_skip(4);
    $self->print_text( $text, $md );
}

sub print_text {
    my ( $self, $text, $xxmd, $font ) = @_;
    $font ||= $self->{ps}->{fonts}->{subtitle};
    $xxmd ||= 0;
    $self->pdf_checkvspace;
    $self->{pr}->text( $text, $x + $xxmd, $y, $font );
}

sub print_hmore {
    return;
    ps_skip(4);
}

sub print_hless {
    return;
    ps_skip(-4);
}

sub print_grids {
    my ( $self, $grids ) = @_;

    my $n = int( ( 570 - $md - 60 ) / 80 );

    my $i = 0;
    foreach my $ch ( @$grids ) {
	$self->print_grid($ch);
	if ( ++$i >= $n ) {
	    $self->print_newline(4);
	    $i = 0;
	}
	else {
	    $self->pdf_gridstep();
	}
    }
    $self->print_newline(3);
}

sub print_grid {
    my ( $self, $grid ) = @_;

    my @c = @$grid;
    my $chord = shift(@c);
    my ( $save_x, $save_y ) = ( $x, $y );
    $y += 0;
    $x += 28;
    if ( $chord =~ /::/ ) {
	$x -= $chord->width($self) / 2;
	$self->pdf_chord($chord);
    }
    else {
	$self->{pr}->ctext( $chord, $x, $y,
			    $self->{ps}->{fonts}->{chord} );
    }
    ( $x, $y ) = ( $save_x, $save_y );

    # Fretboard.
    my $c = shift(@c);
    $self->{pr}->fretboard( $x + $md + 8, $y - 5, 5*8, 4*8, $c, \@c );
}

sub page_settings {
    # Pretty hardwired for now.
    my $ret =
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

    return $ret;
}

################ PDF routines ################

my $pdf_pages = 0;		# physcial page number
my $pdf_page  = 1;		# logical page number

sub pdf_page {
    my ( $self, $first, $title, $stitles ) = @_;

    # Physical newpage, if needed.
    $self->{pr}->newpage if $pdf_pages++;

    # (Re)set coordinates and page number.
    $x = $self->{ps}->{marginleft};
    $y = $self->{ps}->{papersize}->[1] - $self->{ps}->{margintop};
    $pdf_page = $first ? 1 : $pdf_page+1;

    # Print title header.
    $self->{pr}->text( $self->{title} = $title,
		       $x, $y,
		       $self->{ps}->{fonts}->{title} );

    # Add page number, if not first (or only) page.
    if ( $pdf_page > 1 ) {
	$self->{pr}->rtext( "Page $pdf_page",
			    $self->{ps}->{papersize}->[0] - $self->{ps}->{marginright},
			    $y,
			    $self->{ps}->{fonts}->{subtitle},
			  );
    }
    $self->print_newline;

    # Add subtitles, if any,
    foreach ( @$stitles ) {
	$self->{pr}->text( $_, $x, $y,
			   $self->{ps}->{fonts}->{subtitle},
			 );
	$self->print_newline;
    }

    # And finally some vertical space.
    $self->print_newline(2);
}

sub pdf_checkvspace {
    my ( $self ) = @_;

    # Check if this still fits.
    return if $y >= $self->{ps}->{marginbottom};

    # Otherwise, new page.
    $self->pdf_page( 0, $self->{title}, [] );
}

sub pdf_step {
    my ( $self ) = @_;
    $self->pdf_skip($xd);
}

sub pdf_gridstep {
    my ( $self ) = @_;
    $self->pdf_skip(80);
} # #### TODO: what width?

sub pdf_skip {
    my ( $self, $amt ) = @_;
    $x += $amt;
}

sub pdf_chord {
    my ( $self, $chord ) = @_;
    my $save_x = $x;
    $chord->pdf($self);
    $x = $save_x + $xd;
}

# PDF support routines for App::Music::PlayTab::Note.

package App::Music::PlayTab::Note;

# Glyph mappings of the MSyms font.
use constant MS_SHARP    => "\x{0021}";
use constant MS_FLAT     => "\x{0022}";
use constant MS_NATURAL  => "\x{0023}";

sub pdf {
    my ($self, $drv) = @_;
    my $name = $self->name;

    if ( $name =~ /(.)b/ ) {
	my $width = $drv->{pr}->strwidth( $1,
					  $drv->{ps}->{fonts}->{chord});
	$drv->{pr}->text( $1, $x + $md, $y,
			  $drv->{ps}->{fonts}->{chord} );
	$drv->{pr}->msym( MS_FLAT, $x + $md + $width + 1, $y + 3, 25 );
    }
    elsif ( $name =~ /(.)#/ ) {
	my $width = $drv->{pr}->strwidth( $1,
					  $drv->{ps}->{fonts}->{chord});
	$drv->{pr}->text( $1, $x + $md, $y,
			  $drv->{ps}->{fonts}->{chord} );
	$drv->{pr}->msym( MS_SHARP, $x + $md + $width + 1, $y + 3, 25 );
    }
    else {
	$drv->{pr}->text( $name, $x + $md, $y,
			  $drv->{ps}->{fonts}->{chord} );
    }
}

sub width {
    my ($self, $drv) = @_;
    my $name = $self->name;
    my $width = $drv->{pr}->strwidth($name,
				     $drv->{ps}->{fonts}->{chord});

    if ( $name =~ /(.)b/ ) {
	return $drv->{pr}->strwidth( $1, $drv->{ps}->{fonts}->{chord})
	  + 1 + $drv->{pr}->msymwidth( MS_FLAT );
    }
    if ( $name =~ /(.)#/ ) {
	return $drv->{pr}->strwidth( $1, $drv->{ps}->{fonts}->{chord})
	  + 1 + $drv->{pr}->msymwidth( MS_SHARP );
    }

    return $drv->{pr}->strwidth( $name, $drv->{ps}->{fonts}->{chord} );
}

# PDF support routines for App::Music::PlayTab::Chord.

package App::Music::PlayTab::Chord;

# Glyph mappings of the MSyms font.
use constant MS_DIM      => "\x{0027}";
use constant MS_HDIM     => "\x{0028}";
use constant MS_AUG      => "\x{0029}";
use constant MS_MAJOR7   => "\x{002a}";
use constant MS_MINOR    => "\x{002b}";

sub pdf {
    my ($self, $drv) = @_;

    my $width = $self->{key}->width($drv);
    $self->{key}->pdf($drv);

    my $res = "";
    my @v = @{$self->{vec}};
    my $v = "@v ";
    shift (@v);

    if ( $v =~ s/^0 (2 )?4 (6|7|8) / / ) {
	if ( $2 == 8 ) {
	    $drv->{pr}->msym( MS_AUG, $x + $md + $width + 1, $y + 8 );
	}
	$v = ' 6' . $v if $2 == 6;
	$v = ' 2' . $v if defined $1;
    }
    elsif ( $v =~ s/^0 3 6 9 / / ) {
	$drv->{pr}->msym( MS_DIM, $x + $md + $width + 1, $y + 8 );
    }
    elsif ( $v =~ s/^0 (2 )?3 (6|7|8) / / ) {
	if ( $2 == 6 ) {
	    if ( $v =~ s/^ 10 // ) {
		$drv->{pr}->msym( MS_HDIM, $x + $md + $width + 1, $y + 8 );
	    }
	    else {
		$drv->{pr}->msym( MS_DIM, $x + $md + $width + 1, $y + 8 );
	    }
	}
	else {
	    $drv->{pr}->msym( MS_MINOR, $x + $md + $width + 1, $y + 8 );
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
	$drv->{pr}->text( "7", $x + $md + $width + 0.5, $y - 3,
			  $drv->{ps}->{fonts}->{chord}, 12);
    }
    elsif ( $v =~ s/^( \d| 10|) 11 / $1/ ) {
	$res .= ' -2 0 rmoveto' if $res =~ / flat$/;
	$drv->{pr}->msym( MS_MAJOR7, $x + $md + $width + 0.5, $y - 3 );
    }
    if ( $v =~ s/ 5 7 / / ) {
	$res .= ' (4) susp';
    }
    elsif ( $v =~ s/^0 7 / / ) {
	$res .= ' (2) susp';
    }
    elsif ( $v =~ s/^0 4 / / ) {
	$res .= ' (no5) addn';
    }
    my $res1 = $res;		# for debug

    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	$res .= ' ';
	$res .= ( '(1) addn', '(2) addf', '(2) addn', '(3) addf', '(3) addn',
		  '(4) addn', '(5) addf', '(5) addn', '(5) adds', '(6) addn',
		  '(7) addn', '(7) adds', '(8) addn', '(9) addf', '(9) addn',
		  '(9) adds','(11) addf','(11) addn','(11) adds',
		 '(12) addn','(13) addf','(13) addn' )[$_];
    }

    if ( $self->{high} ) {
	my $t = join(" bslash ", map { $_->pdf } @{$self->{high}});
	$t =~ s/root/hroot/g;
	$res = join(" bslash ", $res, $t);
    }

    if ( $self->{bass} ) {
	$drv->{pr}->{pdftext}->save;
	$drv->{pr}->{pdftext}->scale( 0.7, 0.7 );
	$drv->{pr}->text( "/", $x, $y, $drv->{ps}->{fonts}->{chord} );
	foreach ( @{$self->{bass}} ) {
	    $x += 5;
	    $_->pdf($drv);
	}
	$drv->{pr}->{pdftext}->restore;
    }

    warn("=> Chord ", $self->{_unparsed}, ": ", $self->{key}->key,
	 " (", $self->{key}->name, ") [ @{$self->{vec}} ] ->",
	 " $res1 [ $v ] -> $res\n")
      if $self->{_debug};
    return $res;

}

sub width {
    my ($self, $drv) = @_;

    my $width = $self->{key}->width($drv);

    my $res;
    my @v = @{$self->{vec}};
    my $v = "@v ";
    shift (@v);

    if ( $v =~ s/^0 (2 )?4 (6|7|8) / / ) {
	if ( $2 == 8 ) {
	    $width += $drv->{pr}->msymwidth( MS_AUG );
	}
	$v = ' 6' . $v if $2 == 6;
	$v = ' 2' . $v if defined $1;
    }
    elsif ( $v =~ s/^0 3 6 9 / / ) {
	$width += $drv->{pr}->msymwidth( MS_DIM );
    }
    elsif ( $v =~ s/^0 (2 )?3 (6|7|8) / / ) {
	if ( $2 == 6 ) {
	    if ( $v =~ s/^ 10 // ) {
		$width += $drv->{pr}->msymwidth( MS_HDIM );
	    }
	    else {
		$width += $drv->{pr}->msymwidth( MS_DIM );
	    }
	}
	else {
	    $width += $drv->{pr}->msymwidth( MS_MINOR );
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
	$width += $drv->{pr}->strwidth( "7", $drv->{ps}->{fonts}->{chord}, 12);
    }
    elsif ( $v =~ s/^( \d| 10|) 11 / $1/ ) {
	$width += $drv->{pr}->msymwidth( MS_MAJOR7 );
	$res .= ' -2 0 rmoveto' if $res =~ / flat$/;
    }
    if ( $v =~ s/ 5 7 / / ) {
	$res .= ' (4) susp';
    }
    elsif ( $v =~ s/^0 7 / / ) {
	$res .= ' (2) susp';
    }
    elsif ( $v =~ s/^0 4 / / ) {
	$res .= ' (no5) addn';
    }
    my $res1 = $res;		# for debug

    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	$res .= ' ';
	$res .= ( '(1) addn', '(2) addf', '(2) addn', '(3) addf', '(3) addn',
		  '(4) addn', '(5) addf', '(5) addn', '(5) adds', '(6) addn',
		  '(7) addn', '(7) adds', '(8) addn', '(9) addf', '(9) addn',
		  '(9) adds','(11) addf','(11) addn','(11) adds',
		 '(12) addn','(13) addf','(13) addn' )[$_];
    }

    return $width;

    if ( $self->{high} ) {
	my $t = join(" bslash ", map { $_->pdf } @{$self->{high}});
	$t =~ s/root/hroot/g;
	$res = join(" bslash ", $res, $t);
    }

    if ( $self->{bass} ) {
	my $t = join(" slash ", map { $_->pdf } @{$self->{bass}});
	$t =~ s/root/hroot/g;
	$res = join(" slash ", $res, $t);
    }

    warn("=> Chord ", $self->{_unparsed}, ": ", $self->{key}->key,
	 " (", $self->{key}->name, ") [ @{$self->{vec}} ] ->",
	 " $res1 [ $v ] -> $res\n")
      if $self->{_debug};

    return $res;
}

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
    my ( $pkg, $drv, @file ) = @_;
    my $self = bless { drv => $drv }, $pkg;
    $self->{pdf} = PDF::API2->new( -file => $file[0] );
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
    my ( $self, $sym, $x, $y, $size ) = @_;
    my $font = $self->{drv}->{ps}->{fonts}->{msyms};
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
	my $font = $self->{drv}->{ps}->{fonts}->{msyms};
	$size ||= $font->{size};
	$self->setfont($font, $size);
	$self->{pdftext}->advancewidth($sym);
    };
}

sub _text {
    my ( $self, $align, $text, $x, $y, $font, $size ) = @_;

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
	$self->rtext( $r, $x - 3, $y - 4,
		      $self->{drv}->{ps}->{fonts}->{msyms} );
    }
    else {
	$self->hline( $x, $y - 0.7, 5*$cw );
    }

    return unless $dots;

    $x -= $cw / 2;
    $y += $ch / 2;
    foreach my $dot ( @$dots ) {
	if ( $dot < 0 ) {
	    $self->msym( MS_FBX, $x + 1.8, $y - $ch - 2.5, 30 );
	}
	elsif ( $dot > 0 ) {
	    $self->msym( MS_FBFILLED, $x + 1, $y - $ch*$dot - 2.7, 40 );
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
    #$self->{pdftext}->textend if $self->{pdftext};
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
