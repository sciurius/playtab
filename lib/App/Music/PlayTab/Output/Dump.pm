#! perl

# Author          : Johan Vromans
# Created On      : Fri Mar 28 19:42:24 2014
# Last Modified By: Johan Vromans
# Last Modified On: Tue Apr  1 14:18:47 2014
# Update Count    : 21
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::Output::Dump;

use strict;
use warnings;

our $VERSION = "0.001";

sub import { __PACKAGE__ };

sub new {
    bless { raw => 1 }, shift;
}

sub print_finish {
    my $self = shift;
}

sub generate {
    my ( $self, $args ) = @_;
    my $opus = $args->{opus};

    *OUTPUT = *STDOUT;
    use Data::Dumper;
    $Data::Dumper::Indent = 1;
    print OUTPUT ( Data::Dumper->Dump([$opus], ["opus"]) );

}

1;

__END__

=head1 NAME

App::Music::PlayTab::Dump - Debugging dump output.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
