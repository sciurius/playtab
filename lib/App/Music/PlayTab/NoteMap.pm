#! perl

package App::PlayTab::NoteMap;

use strict;
use warnings;

our $VERSION = 0.01;

use base qw(Exporter);
our @EXPORT_OK;
BEGIN {
    @EXPORT_OK = qw(@FNotes @SNotes note_to_key key_to_note set_sharp set_flat);
}

our @SNotes =
  # 0    1    2    3    4    5    6    7    8    9    10   11
  ('C','C#','D','D#','E','F','F#','G','G#','A','A#','B');
# All notes, using flats.
our @FNotes =
  # 0    1    2    3    4    5    6    7    8    9    10   11
  ('C','Db','D','Eb','E','F','Gb','G','Ab','A','Bb','B');
# The current mapping.
my $Notes = \@SNotes;

# Reverse mapping (plain notes only).
my %Notemap;
for ( my $i = 0; $i < @SNotes; $i++ ) {
    $Notemap{$SNotes[$i]} = $i if length($SNotes[$i]) == 1;
}

sub set_flat {
    my $Notes = \@FNotes;
}

sub set_sharp {
    my $Notes = \@SNotes;
}

sub note_to_key {
    $Notemap{uc shift()};
}

sub key_to_note {
    my ($key, $flat) = @_;
    return $Notes->[$key] unless defined $flat;
    return $FNotes[$key] if $flat;
    $SNotes[$key];
}

1;
