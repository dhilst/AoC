#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';

my ($password, $value) = (0, 50);

sub move {
    my ($dir, $num) = /(L|R)(\d+)/;
    return unless defined $dir;
    my $m = $dir eq "L" ? -1 : 1;

    $value = ($value + $m) % 100 or $password++
        while $num--;
}

sub solution {
    move for <>;
    $password;
}

say solution;





