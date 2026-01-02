use v5.36;

use Carp;
use Test::More;
use Data::Dumper;
use File::Slurper qw(read_lines);

package Range {
    use overload
        '""' => sub($self) { join "-", $self->@* };
    
    sub new($cls, $start, $end) {
        ::confess "invalid arguments $start $end"
            unless $start <= $end;
        return bless [$start, $end], $cls;
    }

    sub from_str($str) {
        my ($start, $end) = split /-/, $str;
        Range->new($start, $end);
    }

}

sub aref { \@_ }

sub range($start, $end) {
    Range->new($start, $end)
}

sub fully_contains($range_a, $range_b) {
    my ($a_start, $a_end) = $range_a->@*;
    my ($b_start, $b_end) = $range_b->@*;
    return $a_start <= $b_start && $a_end >= $b_end;
}

sub overlaps($range_a, $range_b) {
    my ($a_start, $a_end) = $range_a->@*;
    my ($b_start, $b_end) = $range_b->@*;
    return $a_start <= $b_end && $a_end >= $b_start;
}

ok(fully_contains(Range->new(1,3), Range->new(2,2)));
ok(fully_contains(Range->new(1,3), Range->new(2,2)));

done_testing;

my @tinput = split /\n/, <<'EOF';
2-4,6-8
2-3,4-5
5-7,7-9
2-8,3-7
6-6,4-6
2-6,4-8
EOF

sub solve(@tinput) {
    scalar
    grep { $_->[-1] }
    map { push $_->@*, fully_contains($_->[-1]->@*) || fully_contains(reverse $_->[-1]->@*); $_ }
    map { push $_->@*, aref map Range::from_str($_), $_->@*; $_ }
    map { aref split ',', $_, 2  }
    @tinput;
}

sub solve_p2(@tinput) {
    scalar 
    grep { $_->[-1] }
    map { push $_->@*, overlaps($_->[-1]->@*) || overlaps(reverse $_->[-1]->@*); $_ }
    map { push $_->@*, aref map Range::from_str($_), $_->@*; $_ }
    map { aref split ',', $_, 2  }
    @tinput;
}

# say Dumper aref solve(@tinput);
# say Dumper aref solve(read_lines("day04.input"));
say Dumper aref solve_p2(read_lines("day04.input"));

