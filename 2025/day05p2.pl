use strict;
use warnings;
use feature 'say';
use File::Slurper qw(read_lines);
use Data::Dumper;
use Test::More;
use Scalar::Util;
use Carp;

package Range;

use overload 
    '""' => sub {
        my ($self) = @_;
        my ($start, $end) = $self->@*;
        return sprintf "%02d-%02d", $start, $end;
    },
    '<=>' => sub {
        my ($self, $other) = @_;
        my ($self_start, $self_end) = $self->@*;
        my ($other_start, $other_end) = $other->@*;

        return $self_start <=> $other_start ||
        $self_end <=> $other_end
    };

sub new {
    my ($cls, $start, $end) = @_;
    ::confess "invalid argument $start $end" unless $start <= $end;
    return bless [$start, $end], $cls;
}

# static
sub sort {
    return sort { 
        ::confess "invalild argument $a" 
            unless Scalar::Util::blessed $a eq "Range";
        ::confess "invalild argument $b" 
            unless Scalar::Util::blessed $b eq "Range";
        $a <=> $b 
    } @_;
}

# static
sub combine {
    my ($range_a, $range_b) = @_;
    my ($a_start, $a_end) = $range_a->@*;
    my ($b_start, $b_end) = $range_b->@*;

    print "==> combining $range_a x $range_b "
        if $ENV{DEBUG};

    my @result;

    if ($a_start <= $b_start && $a_end >= $b_end) {
        @result = ($range_a,);
    } elsif ($b_start <= $a_start && $b_end >= $a_end) {
        @result = ($range_b,);
    } elsif ($a_start <= $b_start
            && $b_start <= $a_end + 1
            && $a_end <= $b_end) {
        @result = (Range->new($a_start, $b_end),)
    } elsif ($b_start <= $a_start
            && $a_start <= $b_end + 1
            && $b_end <= $a_end) {
        @result = (Range->new($b_start, $a_end),);
    } else {
        @result = ($a_start <= $b_start) 
            ? ($range_a, $range_b)
            : ($range_b, $range_a); 
    }

    say "==> ", join " x ", @result
        if $ENV{DEBUG};

    return @result;
}

sub compress {
    my @ranges = Range::sort @_;
    my @out;

    while (@ranges) {
        my $range = shift @ranges;
        last unless defined $range;

        if (@out == 0) {
            push @out, $range;
            next;
        }

        my $last = pop @out;
        my ($r1, $r2) = Range::combine($last, $range);
        if (defined($r2)) {
            push @out, $r1, $r2;
            next;
        }
        unshift @ranges, $r1;
    }

    return @out;
}

sub sum {
    my $sum = 0;
    for my $range (@_) {
        my ($start, $end) = $range->@*;
        $sum += $end - $start + 1;
    }
    return $sum;
}

package Input;

sub new {
    my $cls = shift;

    my @ranges;
    my @ids;
    my $state = 'reading_ranges';
    for my $line (@_) {
        $line =~ s/\n+//g; # chomp trailing newlines
        if ($line eq "") {
            $state = 'reading_ids';
            next;
        }
        if ($state eq 'reading_ranges') {
            my ($start, $end) = map int, split /-/, $line;
            push @ranges, Range->new($start, $end);
        } elsif ($state eq 'reading_ids') {
            push @ids, int $line;
        }

    }
    return bless {
        ranges => \@ranges,
        ids => \@ids,
    }, $cls;
}

sub each(&$) {
    my ($block, $self) = @_;
    for my $range ($self->{ranges}->@*) {
        for my $id ($self->{ids}->@*) {
            $block->($range, $id);
        }
    }
}

package main;

my @test_input = split /\n/, <<"EOF";
3-5
10-14
16-20
12-18

1
5
8
11
17
32
EOF

my $test_obj = Input->new(@test_input);
my @test_ranges = $test_obj->{ranges}->@*;


say join "\n", @test_ranges;
say "-" x 10;
say join "\n", Range::compress @test_ranges;
say "-" x 10;
say join "\n", Range::sum Range::compress @test_ranges;

my @ranges = Input->new(read_lines("day05.input"))->{ranges}->@*;

say scalar @ranges;
say scalar Range::compress @ranges;
say scalar Range::compress @ranges;
say scalar Range::compress Range::compress @ranges;
say scalar Range::sum Range::compress Range::compress Range::compress @ranges;
say join "\n", @ranges;
say "-" x 20;
say join "\n", Range::compress @ranges;
say scalar Range::sum Range::compress @ranges;
