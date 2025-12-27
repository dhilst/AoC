use v5.36;
no autovivification;

use Test::More;
use Data::Dumper;
use File::Slurper qw(read_lines);
use List::Util;

sub aref { \@_; }
sub dref { $_[0]->@*; }

sub is_increasing(@values) {
    my $prev = shift @values;
    for my $current (@values) {
        return 0 unless $prev < $current;
        $prev = $current;
    }
    return 1;
}

sub is_decreasing(@values) {
    my $prev = shift @values;
    for my $current (@values) {
        return 0 unless $prev > $current;
        $prev = $current;
    }
    return 1;
}

sub in_between($a, $b, $c) {
    $a <= $b && $b <= $c;
}

sub at_least_one_at_most_three(@values) {
    my $prev = shift @values;
    for my $current (@values) {
        my $delta = abs($current - $prev);
        return 0 unless in_between(1, $delta, 3);

        $prev = $current;
    }
    return 1;
}

sub parse(@lines) { 
    map { aref map int, split /\s+/, $_ } @lines;
}

sub solve_pt1(@input) {
    grep { (is_increasing(dref $_) || is_decreasing(dref $_)) && at_least_one_at_most_three(dref $_) } @input
}

# -- part 2

sub find_failing_indexes($block, $siz, @values) {
    for (my $i = 0; $i < @values; $i++) {
        my @slice = @values[$i .. $i + $siz - 1];
        last if grep { !defined } @slice;
        return $i unless $block->(@slice);
    }
    undef;
}

sub slide_map :prototype(&$@) ($block, $siz, @values) {
    my @out;
    for (my $i = 0; $i < @values; $i++) {
        my @slice = @values[$i .. $i + $siz - 1];
        last if grep { !defined } @slice;
        push @out, $block->(@slice, $i, $i + $siz - 1);
    }
    @out;
}

sub is_monotonic($a, $b, $c) {
    $a < $b ? $b < $c : $a > $b && $b > $c;
}

sub is_at_least_one_at_most_three ($a, $b) {
    in_between(1, abs($b - $a), 3);
}

sub is_valid($a, $b, $c) {
    is_monotonic($a, $b, $c)
        && is_at_least_one_at_most_three($a, $b)
        && is_at_least_one_at_most_three($b, $c)
}

my sub valid_chunk($a, $b, $c, $start, $end) {
    is_monotonic($a, $b, $c)
    && in_between(1, abs($b - $a), 3)
    && in_between(1, abs($c - $b), 3);
}

my sub valid(@line) {
    (List::Util::all { $_ } slide_map \&valid_chunk, 3, @line)
    ? 1 : 0;
}

sub invalid_indexes(@line) {
    List::Util::uniqint 
        sort { $a <=> $b }
        slide_map
            sub ($a, $b, $c, $start, $end) { 
                return if valid_chunk($a, $b, $c, $start, $end); 
                $start .. $end
            }, 3, @line;
}

sub filter(@line) {
    my @invalid_indexes = invalid_indexes(@line);
    # line is valid, return it
    return -1 unless @invalid_indexes;

    for (@invalid_indexes) {
        my @copy;
        push @copy, @line[0 .. $_ - 1];
        push @copy, @line[$_ + 1 .. $#line];
        return $_ if valid(@copy);
    }

    return undef;
}

sub solve_pt2(@input) {
    grep { filter(dref $_) } @input;
}

my @test_input = parse split /\n/, <<"EOF";
7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9
EOF

is is_increasing(1,2,3,4), 1;
is is_increasing(1,2,3,3), 0;
is is_decreasing(4,3,2,1), 1;
is is_decreasing(4,3,2,2), 0;
is is_decreasing(1,2,3,2), 0;
is at_least_one_at_most_three(1,2,7,8,9), 0;
is at_least_one_at_most_three(1,2,3,4), 1;
is at_least_one_at_most_three(1,4), 1;
is at_least_one_at_most_three(1,5), 0;
is at_least_one_at_most_three(5,1), 0;
is at_least_one_at_most_three(4,1), 1;
is at_least_one_at_most_three(qw(9 7 6 2 1)), 0;
is filter(qw(1 2 3 4 5 4)), 5;



sub try_again(@input) {
    my @out;
    OUTER: for my $line (@input) {
        if (scalar invalid_indexes($line->@*) == 0) {
            push @out, $line;
            next;
        }

        for (my $i = 0; $i < $line->@*; $i++) {
            my @copy = $line->@*;
            splice @copy, $i, 1;
            if (scalar invalid_indexes(@copy) == 0) {
                push @out, $line;
                next OUTER;
            }
        }
    }

    return @out;
}

sub try_again2(@input) {
    my @out;
    OUTER: for my $line (@input) {
        my @invalid_indexes = invalid_indexes($line->@*);
        if (@invalid_indexes == 0) {
            push @out, $line;
            next;
        }

        for my $i (@invalid_indexes) {
            my @copy = $line->@*;
            splice @copy, $i, 1;
            if (scalar invalid_indexes(@copy) == 0) {
                push @out, $line;
                next OUTER;
            }
        }
    }

    return @out;
}


# say Dumper aref try_again(@test_input);
say scalar try_again(parse read_lines("day02.input"));
say scalar try_again2(parse read_lines("day02.input"));

done_testing;

