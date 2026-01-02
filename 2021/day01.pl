use v5.36;

use Data::Dumper;
use File::Slurper qw(read_lines);

my $test_input = <<'EOF';
199
200
208
210
200
207
240
269
260
263
EOF

sub aref { \@_ }

my @lines = split /\n/, $test_input;

sub solve(@lines) {
    my $prev = shift @lines;
    my $count = 0;
    foreach my $line (@lines) {
        say "linha anterior: $prev, linha atual: $line";

        $count = $count + 1 if $line > $prev;

        $prev = $line;
    }
    say $count;
}

my @puzzle_lines = read_lines("day01.input");
say Dumper aref @puzzle_lines;
solve(@puzzle_lines);

