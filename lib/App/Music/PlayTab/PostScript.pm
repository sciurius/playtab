#! perl

# Author          : Johan Vromans
# Created On      : Thu Mar 27 16:46:54 2014
# Last Modified By: Johan Vromans
# Last Modified On: Fri Mar 28 09:26:21 2014
# Update Count    : 52
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::PostScript;

use strict;
use warnings;

our $VERSION = "0.001";

my $preamble;
my $std_width	   =  30;
my $std_height	   = -15;
my $std_margin	   =  40;

sub generate {
    my ( $self, $args ) = @_;
    my $opus = $args->{opus};

    if ( 0 ) {
	use Data::Dumper;
	warn Dumper($opus);
	exit;
    }

    *OUTPUT = *STDOUT;

    $preamble = $args->{preamble};
    ps_preamble();
    set_whmb( $std_width, $std_height, $std_margin, undef );
    print_title( 1, $opus->{title} );
    print_title( 0, $_ ) foreach @{ $opus->{subtitle} };

    foreach my $line ( @{ $opus->{lines} } ) {

	if ( $line->{measures} ) {
	    set_whmb( $line->{width},
		      $line->{height},
		      $line->{margin},
		      $line->{barnumber} );

	    if ( $line->{prefix} && $line->{prefix} ne "" ) {
		print_margin( $line->{pfx_vsp}, $line->{prefix} );
	    }

	    print_bar(1);
	    foreach ( @{ $line->{measures} } ) {
		foreach my $c ( @$_ ) {
		    if ( UNIVERSAL::can( $c, 'ps' ) ) {
			ps_move();
			print_chord($c);
			ps_step();
		    }
		    else {
			my $fun = "print_$c";
			no strict 'refs';
			$fun->();
		    }
		}
		print_bar(0);
	    }
	    if ( $line->{postfix} && $line->{postfix} ne "" ) {
		ps_skip(4);
		ps_move();
		print OUTPUT ('SF (', $line->{postfix}, ') show', "\n");
	    }
	    print_newline(2);
	    next;
	}

	if ( $line->{chords} ) {
	    print_margin( 0, "C H O R D S" );
	    print_newline(1);
	    next;
	}

	if ( $line->{prefix} && $line->{prefix} ne "" ) {
	    print_margin( $line->{pfx_vsp}, $line->{prefix} );
	    print_newline();
	    next;
	}
    }

    ps_trailer();
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
my $std_gridscale = 8;

sub set_whmb {
    ( $xd, $yd, $md, $barno ) = @_;
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

sub print_ta {
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

sub print_hmore {
    ps_skip(4);
}

sub print_less {
    ps_skip(-4);
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
    $x = $y = 0;
}

my @oldmargin;
sub ps_push_actual_margin {
    push(@oldmargin, $xm);
    $xm = shift;
}

sub ps_pop_actual_margin {
    $xm = pop(@oldmargin);
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
	$data = App::Music::PlayTab::PostScript::Preamble->preamble( $_[0] );
    }
    $data =~ s/\$std_gridscale/$std_gridscale/g;
    print OUTPUT ($data);

    $x0 = 50;
    $y0 = 800;
    $x = $y = 0;
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

1;

__END__

=head1 NAME

App::Music::PlayTab::PostScript - PostScript output.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
