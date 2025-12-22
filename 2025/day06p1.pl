use strict;
use warnings;
use feature 'say';

use Data::Dumper;
use File::Slurper qw(read_lines);
use List::Util;
use Carp;


my @test_input = split /\n/, <<"EOF";
123 328  51 64 
 45 64  387 23 
  6 98  215 314
*   +   *   +  
EOF
sub parse {
     map [ grep { $_ } split /\s+/, $_ ], @_;
}

sub enumerate {
    my $i = 0;
    map [ $i++, $_ ], @_;
}

sub column {
    my $col = shift;
    my $rows_aref = shift;
    my @out;
    for my $row ($rows_aref->@*) {
        push @out, $row->[$col];
    }
    return \@out;
}

sub transpose {
    my $matrix_aref = shift;
    my @outm;
    my $number_of_columns = $matrix_aref->[0]->@*;
    for (my $i = 0; $i < $number_of_columns; $i++) {
        push @outm, column($i, $matrix_aref);
    }
    return \@outm;
}

sub compute {
    my $op = pop @_;
    if ($op eq "*") {
        return List::Util::product(@_);
    } elsif ($op eq "+") {
        return List::Util::sum(@_);
    } else {
        confess "invalid argument $op";
    }
}

sub aref {
    return \@_;
}

sub compute_all {
    map { compute $_->@* } transpose(\@_)->@*;
}

sub solve {
    List::Util::sum compute_all @_;
}

my @test = parse @test_input;

say Dumper(\@test);
say "=> ", Dumper(column(0, \@test));
say "=> ", Dumper(transpose(\@test));
say "=> ", Dumper(aref compute_all @test);
say "=> ", solve @test;

my @input = parse read_lines "day06.input";
say solve @input;

