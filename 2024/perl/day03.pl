use v5.36;

use Data::Dumper;
use File::Slurper qw(read_text);

my $test_input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

sub solve {
    my ($input) = @_;
    my $out = 0;
    while ($input =~ /mul\((\d+),(\d+)\)/g) {
        $out += $1 * $2;
    }
    return $out;
}

sub solve2 {
    my ($input) = @_;
    my $out = 0;
    my $do = 1;
    while ($input =~ /(don't\(\)|do\(\)|mul\((\d+),(\d+)\))/g) {
        my ($cmd, $a, $b) = ($1, $2, $3);
        say "cmd = $cmd, (do = $do)";
        if ($cmd eq "do()") {
            $do = 1;
        } elsif ($cmd eq "don't()") {
            $do = 0;
        } elsif (($cmd =~ /^mul/) && $do) {
            say "adding up \$out += $a * $b";
            $out += $a * $b;
        }
    }
    return $out;
}


#say solve $test_input;
#say solve read_text("day03.input");
#say solve2 "mov(1,2);don't();mov(1,1);do();mov(3,3)";
say solve2 read_text("day03.input");

say solve2 "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
