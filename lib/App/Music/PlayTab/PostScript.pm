#! perl

# Author          : Johan Vromans
# Created On      : Thu Mar 27 16:46:54 2014
# Last Modified By: Johan Vromans
# Last Modified On: Thu Mar 27 16:51:33 2014
# Update Count    : 5
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::PostScript;

use strict;
use warnings;

our $VERSION = "0.001";

sub generate {
    my ( $self, $args ) = @_;
    my ( $opus ) = $args->{opus};
    use Data::Dumper;
    warn Dumper($opus);
}

1;

__END__

=head1 NAME

App::Music::PlayTab::PostScript - PostScript output.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
