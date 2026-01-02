use v5.36;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use Test::More;
use List::Util;
use File::Slurper qw(read_lines read_text);
use Carp;

sub aref { \@_ };

package Array {
    sub is_in($value, $array) {
        for ($array->@*) {
            return 1 if $value eq $_;
        }
        return 0;
    }

    # return all values of $array_a that occurs in $array_b
    sub occurs($array_a, $array_b) {
        grep { is_in($_, $array_b) } $array_a->@*;
    }

    sub nth($idx, @array) {
        $array[$idx];
    }
};

is(Array::is_in(1, [1,2,3]), 1);
is_deeply([ Array::occurs([1,2,4], [1,2,3]) ], [1,2]);

my $tinput = <<"EOF";
Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
EOF
chomp $tinput;

sub game_power($winnings_ref) {
    return 0 unless $winnings_ref->@*;
    int(2 ** ($winnings_ref->@* - 1));
}

is(game_power([]), 0);
is(game_power([1]), 1);
is(game_power([1,2]), 2);
is(game_power([1,2,3]), 4);
is(game_power([1,2,3,4]), 8);


sub parse_line($line) {
    my ($id, $payload) = $line =~ /Card\s+(\d+): (.*)$/;
    die "invalid $line" unless defined $id;
    my ($winning_numbers, $my_numbers) = split /\|/, $payload, 2;
    my @winning_numbers = grep { length($_) > 0 } split / +/, $winning_numbers;
    my @my_numbers = grep { length($_) > 0 } split / +/, $my_numbers;
    my @my_winning_numbers = Array::occurs(\@my_numbers,\@winning_numbers);
    my $points = game_power(\@my_winning_numbers);
    { 
            id => $id,
            common => \@my_winning_numbers,
            winning => \@winning_numbers,
            my_numbers => \@my_numbers,
            points => $points,
    }
}
#
sub parse($input_text) {
    my @lines;
    for (split /\n/, $input_text) {
        push @lines, parse_line($_); 
    }
    @lines;
}

sub join_nums(@nums) {
    say Dumper "nums", \@nums;
    join " ", map { sprintf '%2d', $_ } @nums;
}

sub unparse(@parsed) {
    my $max_id = List::Util::max
        map { length($_->{id}) }
        @parsed;
    join "\n", map { 
        sprintf "Card %*d: %s | %s",
            $max_id,
            $_->{id},
            join_nums($_->{winning}->@*),
            join_nums($_->{my_numbers}->@*),
        ;
    } @parsed;
}


# is(unparse(parse($tinput)), $tinput);
say Dumper aref parse_line("Card   1: 34 55 49 53 46  7 82 22 59 33 | 33 29  7 66 22 51 59 21 55 85 53 26 94 46 24 82  6 47 38  2 34 89 49 41 76");
my $input = read_text("day04.input");
my @parsed = parse($input);
is(scalar @parsed, scalar(split /\n/, $input));
is_deeply(aref(split /\n/, unparse(parse($tinput))), aref split /\n/, $tinput);
is_deeply(aref(split /\n/, unparse(parse($input))), aref split /\n/, $input);
# say Dumper aref List::Util::sum map { say Dumper $_; $_->{points} } parse $tinput;
say Dumper aref List::Util::sum map { say Dumper $_; $_->{points} } parse $input;

sub dump_hash($hash_ref) {
    sprintf "{ %s }", join ", ", map { "$_ => $hash_ref->{$_}" } sort { $a <=> $b } keys $hash_ref->%*;
}

sub solve_pt2($tinput) {
    my @tparsed = parse($tinput);
    my %copy_tracker;
    for my $game (@tparsed) {
        my $in_common = scalar $game->{common}->@*;
        $copy_tracker{$game->{id}}++;
        my @next_copies = ($game->{id} + 1 .. $game->{id} + $in_common);
        $copy_tracker{$_} += $copy_tracker{$game->{id}} for @next_copies;
        say "$game->{id} in_cmmon=$in_common", " next_copies=", join(",", @next_copies), " tracker=", dump_hash \%copy_tracker;
    }
    List::Util::sum values %copy_tracker;
}

say solve_pt2($tinput);
say solve_pt2($input);

done_testing;
