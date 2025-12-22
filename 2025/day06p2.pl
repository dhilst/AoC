use strict;
use warnings;
use feature 'say';

use Data::Dumper;
use File::Slurper qw(read_lines);
use List::Util;
use Carp;

sub aref {
    return \@_;
}

sub dref {
    return $_[0]->@*;
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

sub split_at_empty_column {
    # expects the transposed matrix
    my $matrix_aref = shift;
    my @out;
    my @group;
    for my $row_aref ($matrix_aref->@*) {
        my $row_str = join "", $row_aref->@*;
        if ($row_str =~ /^\s+$/) {
            push @out, [ @group ];
            @group = ();
            next;
        }

        push @group, join "", map { s/\s+//r } $row_aref->@*;
    }
    push @out, [ @group ];

    return \@out;
}

sub compute_one {
    my $first_operand_and_operator = shift;
    my ($first_operand, $op) = $first_operand_and_operator =~ /(\d+)(\*|\+)/;
    confess "invalid input $first_operand_and_operator"
        unless defined $first_operand;

    my @other_nums = map int, @_;
    if ($op eq "*") {
        return List::Util::product($first_operand, @other_nums);
    } elsif ($op eq "+") {
        return List::Util::sum($first_operand, @other_nums);
    } else {
        confess "invalid op $op";
    }
}

sub compute_all {
    my $aref = shift;
    aref map { compute_one($_->@*) } $aref->@*;
}


my @test_input = split /\n/, <<"EOF";
123 328  51 64 
 45 64  387 23 
  6 98  215 314
*   +   *   +  
EOF

sub parse {
     map [ grep { $_ } split /\s+/, $_ ], @_;
}

sub parse_p2 {
    aref map [ grep { $_ } split //, $_ ], @_;
}

say List::Util::sum dref 
    compute_all split_at_empty_column transpose
    parse_p2 @test_input;

sub enumerate {
    my $i = 0;
    map [ $i++, $_ ], @_;
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

# sub compute_all {
#     map { compute $_->@* } transpose(\@_)->@*;
# }

sub solve {
    List::Util::sum compute_all @_;
}

my @test = parse @test_input;

# say Dumper(\@test);
# say "=> ", Dumper(column(0, \@test));
# say "=> ", Dumper(transpose(\@test));
# say "=> ", Dumper(aref compute_all @test);
# say "=> ", solve @test;

my @input = read_lines "day06.input";

# say Dumper(List::Util::sum map { compute_one($_->@*) } dref split_at_empty_column transpose aref parse_p2 @input);
