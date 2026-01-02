use v5.36;

use Carp;
use Data::Dumper;
use Test::More;
use List::Util;
use File::Slurper qw(read_text);

sub aref { \@_ }

my $tinput = <<'EOF';
vJrwpWtwJgWrhcsFMMfFFhFp
jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
PmmdzqPrVvPwwTWBwg
wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
ttgJtRGJQctTZtZT
CrZsJsPPZsGzwwsLwLmpwMDw
EOF

sub split_by($num, @array) {
    my @out;
    my $middle = [];
    while (@array) {
        my $i = 0;
        push $middle->@*, shift @array while $i++ < $num;
        push @out, $middle;
        $middle = [];
    }
    @out;
}


sub intersect_string($str_a, $str_b) {
    my @out;
    for (split //, $str_a) {
        push @out, $_ if index($str_b, $_) != -1;
    }
    return join "", List::Util::uniq @out;
}

sub intersect_all(@strings) {
    my $result = intersect_string(shift @strings, shift @strings);
    for (@strings) {
        $result = intersect_all($result, $_);
    }
    $result;
}



is(intersect_string("abc", "bcd"), "bc");
is(intersect_string("abc", "def"), "");

sub letter_to_int($letter) {
    local $_ = $letter;
    if (/[A-Z]/) {
        return ord($letter) - ord('A') + 27;
    } elsif (/[a-z]/) {
        return ord($letter) - ord('a') + 1;
    } else {
        ::confess "invalid letter $letter";
    }
}
# map { is(letter_to_int($_->[0]), $_->[1]) }
# List::Util::zip ['a' .. 'z'], [1 .. 26];
# map { is(letter_to_int($_->[0]), $_->[1]) }
# List::Util::zip ['A' .. 'Z'], [27 .. 52];
#
sub solve_p2($tinput) {
    List::Util::sum
        map { pop $_->@* }
        map { push $_->@*, letter_to_int($_->[-1]); $_ }
        map { push $_->@*, intersect_all($_->@*); $_ }
        split_by 3,
        split /\n/, $tinput;
}


sub split_in_half($str) {
    my $pivot = length($str) / 2;
    [ substr($str, 0, $pivot), substr($str, $pivot) ];
}

sub solve($tinput) {
    List::Util::sum
    map { $_->[-1] }
    map { say Dumper $_; $_ }
    map { [$_->@*, letter_to_int($_->[-1]) ] }
    map { [$_->@*, intersect_string($_->@*)] }
    map { split_in_half($_) }
    split /\n/, $tinput;
}

# say Dumper aref solve($tinput);
# say Dumper aref solve(read_text("day03.input"));
say Dumper aref solve_p2(read_text("day03.input"));

done_testing;
