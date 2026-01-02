use v5.36;

use Data::Dumper;
use List::Util;
use Carp;
use File::Slurper qw(read_lines);

my @tinput = split /\n/, <<"EOF";
Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
EOF

sub aref { \@_ }

sub group_colors($str) {
    my %out;
    while ($str =~ /(?<num>\d+) (?<color>red|green|blue)/g) {
        push $out{$+{color}}->@*, int($+{num});
    }
    \%out;
}

sub parse_line($line) {
    my ($id, $payload) = $line =~ /Game (\d+): (.*)/;
    confess "undefined payload at $line" unless defined($payload);
    my @rounds =  split /; /, $payload;
    {
        id => $id,
        colors => group_colors $payload,
    }
}

sub parse(@lines) {
    map { parse_line($_) } @lines;
}

my ($RED, $GREEN, $BLUE) = (12, 13, 14);


    # say Dumper group_colors("3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green ");
sub solve(@tinput) {
    List::Util::sum
    map { 
        $_->{id}
    }
    grep { 
        my $colors = $_->{colors}; 
        my @red = grep { $_ > $RED } $colors->{red}->@*;
        my @green = grep { $_ > $GREEN } $colors->{green}->@*;
        my @blue = grep { $_ > $BLUE} $colors->{blue}->@*;
        !@red && !@green && !@blue;
    } parse(@tinput);
}

say solve(@tinput);
my @input =read_lines("day02.input");
say solve @input;


sub solve2(@input) {
    List::Util::sum
    map { 
        my $colors = $_->{colors}; 
        my $red = List::Util::max $colors->{red}->@*;
        my $green = List::Util::max $colors->{green}->@*;
        my $blue = List::Util::max $colors->{blue}->@*;
        $red * $green * $blue
    } parse(@input);
}

say solve2 @input;
