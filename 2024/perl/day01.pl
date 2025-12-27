use strict;
use warnings;
use feature 'say';

use Data::Dumper;
use List::Util;
use File::Slurper qw(read_lines);

sub aref { \@_; }
sub dref { (shift)->@*; }
 
my @test_input = split /\n/, <<"EOF";
3   4
4   3
2   5
1   3
3   9
3   3
EOF

sub parse {
    my @input = @_;
    my @columns = ([], []);
    my @lines = map { aref split /\s+/, $_ } @input;

    for (@lines) {
        my ($left, $right) = dref $_;
        push $columns[0]->@*, int $left;
        push $columns[1]->@*, int $right;
    };
    $columns[0] = aref sort $columns[0]->@*;
    $columns[1] = aref sort $columns[1]->@*;
    return @columns;
}

sub solve {
    my @columns = parse @_;
    my @out;
    for my $pair (List::Util::zip @columns) {
        my ($a, $b) = $pair->@*;
        push @out, abs $a - $b;
    }
    List::Util::sum @out;
}

sub solve_p2 {
    my @columns = parse @_;
    my @out;
    for my $pair (List::Util::zip @columns) {
        my ($a, $b) = $pair->@*;
        push @out, $a * scalar grep { $_ == $a } $columns[1]->@*;
    }
    List::Util::sum @out;
}

say solve @test_input;
say solve_p2 @test_input;
say solve read_lines "day01.input";
say solve_p2 read_lines "day01.input";


