#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use Data::Dumper qw(Dumper);
use Scalar::Util qw(looks_like_number);
use List::Util qw(sum);
use Test::More;
use Carp qw(croak);


sub parse_range {
    my ($start, $end) = split /-/, $_[0], 2;
    croak "Invalid range $_[0]"
        unless looks_like_number($start) 
            && looks_like_number($end);
    return ($start..$end);
}

sub parse_line {
    map { [ parse_range $_ ] } split(/,/, $_[0]);
}

# 
sub chunks {
    my ($strinput, $step) = @_;
    die "Expect step to be > 0, found $step"
        unless $step > 0;

    my $max = length($strinput) - $step;
    my @out;
    for (my $i = 0; $i <= $max; $i += $step) {
        push @out, substr($strinput, $i, $step)
    }
    return \@out;
}

sub invalid {
    my ($input) = @_;
    croak "invalid input $input"
        unless looks_like_number($input);
    my $len = length($input);
    return 0 if $len % 2 != 0;
    my $chunksp = chunks $input, $len / 2;

    for my $chunk ($chunksp->@*) {
        my $result = $input =~ s/$chunk//gr;
        return 1 if length $result == 0;
    }

    return 0;
}

sub collect_invalids {
    my ($line) = @_;
    my @input = parse_line $line;

    my @out;
    for my $range (@input) {
        for my $id ($range->@*) {
            push @out, $id
                if invalid($id);
        }
    }

    return \@out;
}


my $test_input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

is_deeply [ parse_range('1-3') ], [ 1,2,3 ];
is_deeply [ parse_line('1-3,9-12') ], [ [1,2,3],[9,10,11,12] ];
is_deeply chunks("aabbcc", 2), [ "aa", "bb", "cc" ];
is invalid(10), 0;
is invalid(11), 1;
is invalid(6464), 1;
is invalid(6465), 0;

my $invalids = collect_invalids $test_input;
is sum($invalids->@*), 1227775554;

open my $fh, "<", "day02.input"
    or die "no day02.input found: $!";

my $prod_input = <$fh>;

close $fh;

say sum(collect_invalids($prod_input)->@*);





done_testing;
