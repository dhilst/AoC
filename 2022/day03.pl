use v5.10;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use File::Slurper qw(read_text);
use Test::More;
use Test::Exception;
use List::Util;

sub aref { \@_ }
sub href { my $href = { @_ }; $href }

sub most_common {
    my ($str) = @_;
    my @chars = split //, $str;
    my %counter;
    $counter{$_}++ for @chars;
    my $max = List::Util::max values %counter;
    my $max_num = scalar grep { $_ == $max } values %counter;
    die "multiple most commons $str: "
        if $max_num > 1;

    my @keys = 
        sort { $counter{$b} <=> $counter{$a} }
        keys %counter;
    List::Util::first { 1 } @keys;
}

sub least_common {
    my ($str) = @_;
    my @chars = split //, $str;
    my %counter;
    $counter{$_}++ for @chars;
    my $min = List::Util::min values %counter;
    my $min_num = scalar grep { $_ == $min } values %counter;
    die "multiple most commons $str: "
        if $min_num > 1;

    my @keys = 
        sort { $counter{$a} <=> $counter{$b} }
        keys %counter;
    List::Util::first { 1 } @keys;
}

sub parse {
    my ($str) = @_;
    map [ split //, $_ ], split /\n/, $str;
}

sub column {
    my $col = shift;
    my @out;
    my $max_col = scalar @{$_[0]};
    confess "invalid col assertion $col < $max_col failed"
        unless 0 <= $col  && $col < $max_col;
    for my $row (@_) {
        push @out, $row->[$col];
    }
    @out;
}

sub transpose {
    my @columns;
    my $max_col = scalar @{$_[0]};
    for my $col (0 .. $max_col - 1) {
        push @columns, [ column($col, @_) ];
    }
    @columns;
}

sub bin_to_int {
    my ($bin_str) = @_;
    confess unless $bin_str =~ /^[01]+$/;
    oct("0b$bin_str");
}

sub most_common_factor {
    bin_to_int
    join "",
    map { most_common(join "", @$_) }
    @_
}

sub least_common_factor {
    bin_to_int
    join "",
    map { least_common(join "", @$_) }
    @_
}

sub solve {
    most_common_factor(@_) * least_common_factor(@_);
}

is(most_common("1110022"), 1);
is(most_common("1120022"), 2);
is(most_common("1120002"), 0);

my @matrix = (
    [1,2,3],
    [4,5,6],
    [7,8,9],
);

is_deeply([ column(0, @matrix) ], [1,4,7]);
is_deeply([ column(1, @matrix) ], [2,5,8]);
is_deeply([ column(2, @matrix) ], [3,6,9]);
dies_ok { column(3, @matrix) };
dies_ok { column(-1, @matrix) };


#
is_deeply(
    [ transpose(@matrix) ],
    [[1,4,7],
     [2,5,8],
     [3,6,9]] );

my $text = <<'EOF';
00100
11110
10110
10111
10101
01111
00111
11100
10000
11001
00010
01010
EOF

# part 2

package Int {
    sub from_bin_str {
        my ($bin_str) = @_;
        ::confess "invalid argumnt $bin_str" 
            unless $bin_str =~ /^[01]+$/;
        oct("0b$bin_str");
    }
}

package String {
    sub get {
        substr($_[1], $_[0], 1);
    }

    sub most_common_char {
        my ($str, %opts) = @_;
        my $ord = $opts{-ord} //= "desc";
        ::confess "invalid argument $ord"
            unless $ord =~ /(desc|asc)/;
        my %counter;
        $counter{$_}++ for split //, $str;
        my @sorted_keys = sub {
            if ($ord eq "desc") {
                # fallback to key order to by pass hash randomization
                # and have deterministic code
                return sort { $counter{$b} <=> $counter{$a} || $a <=> $b } keys %counter;
            } else {
                return sort { $counter{$a} <=> $counter{$b} || $a <=> $b } keys %counter;
            }
        }->();
        my $candidate = List::Util::first { 1 } @sorted_keys;
        my $max_frequency = $counter{$candidate};
        my $all_max = scalar grep { $max_frequency == $_ } values %counter;

        wantarray 
            #               1  if there are multiple max/min
            ? ($candidate, $all_max > 1)
            : $candidate;
    }

    ::is(most_common_char("1110"), 1);
    ::is(most_common_char("1110", -ord => "asc"), 0);
    ::is_deeply([ most_common_char("1100") ], [0, 1]);
}

package StringMatrix {
    sub row {
        my $row = shift;
        $_[$row];
    }

    sub col {
        my $col_idx = shift;
        my @col;
        for my $row (@_) {
            push @col, String::get($col_idx, $row);
        }
        join "", @col;
    }
}

sub find {
    my ($tinput, $missing) = @_;
    my @rows = split /\n/, $tinput;
    my $max_col = length $rows[0];
    for my $col (0 .. $max_col - 1) {
        my ($most_common_char, $multiple_maxes) = String::most_common_char StringMatrix::col($col, @rows),
            -ord => $missing == 1 ? "desc" : "asc";
        ::confess "invalid most_common_char $most_common_char, expected 1 or 0"
            unless $most_common_char =~ /^[01]$/;
        ::confess "undefined multiple_maxes"
            unless defined $multiple_maxes;
        @rows = 
            $multiple_maxes
            ? grep { String::get($col, $_) eq $missing } @rows
            : grep { String::get($col, $_) eq $most_common_char } @rows;
        # say "Step $col: common: $most_common_char, multi max: <$multiple_maxes>, rows:\n", join "\n", @rows;

        if (@rows == 1) {
            return Int::from_bin_str($rows[0]);
        }
    }

    die "oops";
}

sub solve_pt2 {
    my ($tinput) = @_;
    find($tinput, 1) * find($tinput, 0);
}

say solve_pt2 $text;
say solve_pt2 read_text("day03.input");

done_testing;
