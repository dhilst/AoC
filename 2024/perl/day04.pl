#!/usr/bin/env perl

use v5.36;

use File::Slurper qw(read_lines);
use Data::Dumper;



# Read input grid
my @grid = map { chomp; $_ } <STDIN>;

sub gpt_solution {
    my $rows = @_;
    my $cols = length $_[0];
    my $count = 0;
    # Loop excluding borders (since diagonals are needed)
    for my $r (1 .. $rows - 2) {
        for my $c (1 .. $cols - 2) {

            # Center must be 'A'
            next unless substr($_[$r], $c, 1) eq 'A';

            # Diagonals
            my $tl = substr($_[$r-1], $c-1, 1);
            my $tr = substr($_[$r-1], $c+1, 1);
            my $bl = substr($_[$r+1], $c-1, 1);
            my $br = substr($_[$r+1], $c+1, 1);

            # Each diagonal must be MAS or SAM
            my $diag1 =
            ($tl eq 'M' && $br eq 'S') ||
            ($tl eq 'S' && $br eq 'M');

            my $diag2 =
            ($tr eq 'M' && $bl eq 'S') ||
            ($tr eq 'S' && $bl eq 'M');

            $count++ if $diag1 && $diag2;
        }
    }
    return $count;
}

sub my_solution{
    my $count = 0;
    for my $row (1 .. $#_ - 1) {
        for my $col (1 .. length($_[0]) - 1) {
            next if substr($_[$row], $col, 1) ne 'A';
            my $top_left = substr($_[$row-1], $col - 1, 1);
            my $top_right = substr($_[$row-1], $col + 1, 1);
            my $bottom_left = substr($_[$row+1], $col - 1, 1);
            my $bottom_right = substr($_[$row+1], $col + 1, 1);
            my $diag1 = "${top_left}A${bottom_right}";
            my $diag2 = "${top_right}A${bottom_left}";
            # say "found $diag1 $diag2";
            $count++ if
            $diag1 =~ /(?:SAM|MAS)/ && 
            $diag2 =~ /(?:SAM|MAS)/;
        }
    }
    return $count;
}


# my @input = map { chomp; $_; } read_lines("day04.input");
my @input = map { chomp; $_ } split /\n/, <<"EOF";
MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
EOF


say gpt_solution(@input);
say my_solution(@input);
