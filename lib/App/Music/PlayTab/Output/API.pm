#! perl

# Author          : Johan Vromans
# Created On      : Thu Mar 27 16:46:54 2014
# Last Modified By: Johan Vromans
# Last Modified On: Sun May 18 21:31:18 2014
# Update Count    : 238
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::Output::API;

use strict;
use warnings;

our $VERSION = "0.001";

# Object management.

sub new {			# API
    bless { init => 0 }, shift;
}

# Init the backend.
sub setup {			# API
    my ( $self, $args ) = @_;
    ...
}

# New page.
sub setuppage {			# API
    my ( $self, $title, $stitles ) = @_;
    ...
}

sub finish {			# API
    my $self = shift;
    ...
}

# New print line.
sub setupline {			# API
    my ( $self, $line ) = @_;
    ...
}

sub chord {			# API
    my ( $self, $chord, $dup ) = @_;
    ...
}

sub bar {			# API
    my ( $self, $first ) = @_;
    ...
}

sub newline {			# API
    my ( $self, $count ) = @_;
    ...
}

sub postfix {			# API
    my ( $self, $text ) = @_;
    ...
}

sub text {			# API
    my ( $self, $text, $xxmd, $font ) = @_;
    ...
}

sub grids {			# API
    my ( $self, $grids ) = @_;
    ...
}

1;

__END__

=head1 NAME

App::Music::PlayTab::Output::API - Output API description.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
