#! perl

# Author          : Johan Vromans
# Created On      : Thu Mar 27 16:46:54 2014
# Last Modified By: Johan Vromans
# Last Modified On: Thu Apr 17 15:02:47 2014
# Update Count    : 169
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::Output;

use strict;
use warnings;

our $VERSION = "0.001";

sub new {
    my ( $pkg, $args ) = @_;
    my $self = bless {}, $pkg;

    my $generator = $args->{generate};
    my $genpkg = __PACKAGE__ . "::" . $generator;
    eval "use $genpkg";
    die("Cannot find backend for $generator\n$@") if $@;
    $self->{generator} = $genpkg->new($args);

    if ( $args->{output} && $args->{output} ne "-" ) {
	open( $self->{fh}, '>', $args->{output} )
	  or die( $args->{output}, ": $!\n" );
	$self->{fhneedclose} = 1;
    }
    else {
	$self->{fh} = *STDOUT;
	$self->{fhneedclose} = 0;
    }

    $self;
}

sub finish {
    my $self = shift;
    return unless $self->{generator};
    $self->{generator}->print_finish;
    undef $self->{generator};
    $self->{fh}->close if $self->{fhneedclose};
}

sub DESTROY {
    &finish;
}

sub generate {
    my ( $self, $args ) = @_;

    my $gen = $self->{generator};
    $gen->{fh} = $self->{fh};
    if ( $gen->{raw} ) {
	$gen->generate($args);
	return;
    }

    my $opus = $args->{opus};

    $gen->print_setup( $args );
    $gen->print_setuppage( $opus->{title}, $opus->{subtitle} );
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

	    if ( $line->{pfx_vsp} && $prev_line ) {
		$gen->print_newline( $line->{pfx_vsp} );
	    }

	    if ( $line->{prefix} && $line->{prefix} ne "" ) {
		$gen->print_text( $line->{prefix} );
	    }

	    $gen->print_grids( $line->{chords} );
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
