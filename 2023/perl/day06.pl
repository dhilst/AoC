use v5.36;

use Data::Dumper;
use List::Util;
use Test::More;
use Carp;
use File::Slurper qw(read_text);

sub aref { \@_ }

package Array {
    sub equal($array_a, $array_b, @ignored) {
        return 0 if $#$array_a != $#$array_b;

        List::Util::all { $_->[0] eq $_->[1] }
        List::Util::zip $array_a, $array_b
    }

    ::ok(equal([1,2,3],[1,2,3]));
    ::ok(!equal([1,2,3],[1,2,4]));
}

package Input {
    use overload
        '""' => \&unparse,
        '==' => \&equal,
        'fallback' => 0;
        ;

    sub equal($self, $other, $swap = 0) {
        return Input::equal($other, $self) if $swap;
    
        Array::equal($self->{distances}, $other->{distances});
    }

    sub new ($cls, $input) {
        my (@times, @distances);
        for (split /\n/, $input) {
            chomp;
            if (/^Time:/) {
                push @times, int($&) while /\d+/g;
            } elsif (/^Distance:/) {
                push @distances, int($&) while /\d+/g;
            }
        }

        bless {
            times => \@times,
            distances => \@distances,
        }, $cls;
    }

    sub parse($cls, $input) {
        Input->new($input);
    }

    sub parse_p2($cls, $input) {
        my (@times, @distances);
        for (split /\n/, $input) {
            chomp;
            if (/^Time:/) {
                push @times, int($&) while /\d+/g;
            } elsif (/^Distance:/) {
                push @distances, int($&) while /\d+/g;
            }
        }

        bless {
            times => [ join "", @times ],
            distances => [ join "", @distances ],
        }, $cls;
    }

    sub unparse($self, @ignored) {
        my $maxlen = length(List::Util::max($self->{times}->@*, $self->{distances}->@*));
        my $buf; 
        $buf .= "Time:    ";
        $buf .= join " ", map { sprintf "%*d", $maxlen, $_ } $self->{times}->@*;
        $buf .= "\n";
        $buf .= "Distance:";
        $buf .= join " ", map { sprintf "%*d", $maxlen, $_ } $self->{distances}->@*;
        $buf .= "\n";
        $buf;
    }

    sub map($self, $cb) {
        my @out;
        for (List::Util::zip $self->{times}, $self->{distances}) {
            my ($time, $distance) = $_->@*;
            push @out, $cb->($time, $distance);
        }
        @out;
    }
}

sub distance($hold_buttom_time, $total_time) {
    $hold_buttom_time * ($total_time - $hold_buttom_time);
}

sub find_ways_to_win($total_time, $current_record) {
    use integer;
    my $t_down = my $t_up = $total_time / 2;
    $t_up++;
    my @out;
    while ($t_down > 0 && $t_up < $total_time) {
        unshift @out, { input => $t_down, output => distance($t_down, $total_time) };
        push @out, { input => $t_up, output => distance($t_up, $total_time) };
        last if $out[0]->{output} < $current_record || $out[-1]->{output} < $current_record;
        $t_down--;
        $t_up++;
    }
    shift @out while $out[0]->{output} <= $current_record;
    pop @out while $out[-1]->{output} <= $current_record;
    scalar @out;
}

sub solve($tinput) {
    List::Util::product
    $tinput->map(sub ($time, $distance) {
        find_ways_to_win($time, $distance);
    });
}

my $tinput_str = <<"EOF";
Time:      7  15   30
Distance:  9  40  200
EOF

# is(find_ways_to_win(7, 9), 4);
# is(find_ways_to_win(15, 40), 8);
# is(find_ways_to_win(30, 200), 9);

my $tinput = Input->new($tinput_str);
is_deeply($tinput, Input->new($tinput->unparse));
my $tinput_p2 = Input->parse_p2($tinput_str);
say solve($tinput);
say solve($tinput_p2);

my $input = Input->new(read_text("day06.input"));
say solve($input);
say solve(Input->parse_p2(read_text("day06.input")));

# say distance($_, 7) for (0 .. 7);
# say "---";
# say ((distance($_ + 1, 7) + distance($_, 7)) / 2) for (0 .. 7);

done_testing;
