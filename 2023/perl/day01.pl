use v5.36;

use Data::Dumper;
use List::Util;
use Scalar::Util qw(looks_like_number);
use File::Slurper qw(read_lines);


my @tinput = split /\n/, <<"EOF";
1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet
EOF

sub aref { \@_ }

sub read_line($line) {
    my @out;
    my %map = (
        one => 1,
        two => 2,
        three => 3,
        four => 4,
        five => 5,
        six => 6,
        seven => 7,
        eight => 8,
        nine => 9,
    );
    while ($line =~ /(one|two|three|four|five|six|seven|eight|nine|\d)/g) {
        pos($line) = pos($line) - length($1) + 1;
        if (looks_like_number($1)) {
            push @out, int $1
        } else {
            die unless exists $map{$1};
            push @out, $map{$1};
        }
    }
    return join "", @out;
}

my @tinput2 = split /\n/, <<"EOF";
two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
EOF

sub first_last($str) {
    substr($str, 0, 1) . substr($str, length($str) - 1, 1);
}


# say List::Util::sum map { int join "", shift $_->@*, (pop $_->@* // "") } map { [ read_line $_ ] } @tinput2;
my $line = 0;
my @lines = read_lines("day01.input");
my $count = 0;
say join "\n", map { $count += first_last(read_line($_)); join " ", $line++, $_, read_line($_), first_last(read_line($_)) } @lines;
# say join "\n", map { $count += first_last(read_line($_)); join " ", $line++, $_, read_line($_), first_last(read_line($_)) } @tinput2;
say $count;



