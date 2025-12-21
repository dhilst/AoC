#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use Test::More;
use Data::Dumper qw(Dumper);
use List::Util qw();

sub chunk_string {
    my ($input, $siz) = @_;
    my @out = $input =~ /.{$siz}/g;
    return \@out;
}

sub find_max {
    my $max = shift;
    my $pos = 0;
    my $i = 1;
    for (@_) {
        if ($_ > $max) {
            $pos = $i;
            $max = $_;
        }
        $i++;
    }
    return $pos;
}

sub find_max_after {
    my $after = shift() + 1;
    die unless $after > 0;
    my $arrayref = shift;
    die if $after > $arrayref->@*;
    my @slice = @$arrayref[$after..$#{$arrayref}];
    return find_max(@slice) + $after;
}

sub find_joultage {
    my ($input) = @_;
    $input //= $_;
    my $digits = chunk_string($input, 1);
    my $max_pos = find_max($digits->@*);
    my $max = $digits->[$max_pos];
    my $snd_max_pos = undef;
    if ($max_pos + 1 == $digits->@*) {
        # This is a special case, the 9 is in the 
        # end of the input so we have to scan for
        # the max number before it
        $snd_max_pos = find_max($digits->@[0 .. $#{$digits} - 1]);
        my $snd_max = $digits->[$snd_max_pos];
        return int(sprintf "%d%d", $snd_max, $max);
    } else {
        $snd_max_pos = find_max_after($max_pos, $digits);
    }
    my $snd_max = $digits->[$snd_max_pos];
    return int(sprintf "%d%d", $max, $snd_max);
}

sub collect_joultage {
    return [ map { find_joultage($_) } @_ ];
}

sub solve {
    return List::Util::sum(collect_joultage(@_)->@*);
}

is_deeply(chunk_string("1234", 1), ["1", "2", "3", "4"]);
is find_max(1,2,3,4), 3;
is find_max(5,2,3,4), 0;
is find_max(5,8,3,4), 1;
is find_max_after(1, [5,8,4,3]), 2;

is(find_joultage("987654321111111"), 98);
is(find_joultage("811111111111119"), 89);
is(find_joultage("234234234234278"), 78);
is(find_joultage("818181911112111"), 92);

my @test_input = split /\n/, <<"EOF";
987654321111111
811111111111119
234234234234278
818181911112111
EOF

is_deeply(collect_joultage(@test_input), [98, 89, 78, 92]);
is(solve(@test_input), 357);

open my $fh, "<", "day03.input";
my @input = <$fh>;
close $fh;

say solve(@input);


done_testing;

