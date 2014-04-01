#! perl

# Author          : Johan Vromans
# Created On      : Thu Mar 27 16:46:54 2014
# Last Modified By: Johan Vromans
# Last Modified On: Tue Apr  1 14:18:08 2014
# Update Count    : 155
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::Output;

use strict;
use warnings;

our $VERSION = "0.001";

sub new {
    my ( $pkg, $args ) = @_;
    my $self = bless {}, $pkg;

    my $generator = $args->{generate};
    $generator = 'PostScript' if $generator eq 'ps';
    $generator = 'PDF' if $generator eq 'pdf';
    my $genpkg = __PACKAGE__ . "::" . $generator;
    eval "use $genpkg";
    die("Cannot find backend for $generator\n$@") if $@;
    $self->{generator} = $genpkg->new($args);

    $self;
}

sub finish {
    my $self = shift;
    return unless $self->{generator};
    $self->{generator}->print_finish;
    undef $self->{generator};
}

sub DESTROY {
    &finish;
}

sub generate {
    my ( $self, $args ) = @_;

    my $gen = $self->{generator};
    if ( $gen->{raw} ) {
	$gen->generate($args);
	return;
    }

    my $opus = $args->{opus};

    $gen->print_setup( $args );
    $gen->print_title( 1, $opus->{title} );
    $gen->print_title( 0, $_ ) foreach @{ $opus->{subtitle} };
    $gen->print_newline(2);
    my $prev_line = "";

    foreach my $line ( @{ $opus->{lines} } ) {

	$gen->print_setupline($line);

	if ( $line->{measures} ) {

	    if ( $prev_line eq 'bars' ) {
		$gen->print_newline();
	    }
	    if ( $line->{prefix} && $line->{prefix} ne "" ) {
		$gen->print_newline( $line->{pfx_vsp} )
		  if $prev_line;
		$gen->print_text( $line->{prefix} );
	    }
	    elsif ( $line->{pfx_vsp} ) {
		$gen->print_newline( $line->{pfx_vsp} - 1 )
		  if $prev_line;
	    }

	    $gen->print_bar(1) if @{ $line->{measures} };
	    foreach ( @{ $line->{measures} } ) {
		foreach my $c ( @$_ ) {
		    $gen->print_chord($c);
		}
		$gen->print_bar(0);
	    }
	    if ( $line->{postfix} && $line->{postfix} ne "" ) {
		$gen->print_postfix( $line->{postfix} );
	    }
	    $gen->print_newline();
	    $prev_line = 'bars';
	    next;
	}

	if ( $line->{chords} ) {
	    $gen->print_text("C H O R D S");
	    $gen->print_newline();
	    $prev_line = 'chords';
	    next;
	}

	if ( $line->{prefix} && $line->{prefix} ne "" ) {
	    $gen->print_text( $line->{prefix} );
	    $gen->print_newline();
	    $prev_line = 'text';
	    next;
	}
    }
}

1;

__END__

=head1 NAME

App::Music::PlayTab::Output - Output driver.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
