use v5.36;
use builtin qw(true false);

use Data::Dumper;
use List::Util;
use Carp;
use File::Slurper qw(read_lines);
use Scalar::Util qw(looks_like_number);
use Term::ANSIColor qw(:constants);
use Test::More;

sub aref { \@_ }

package Array {
    sub uniq_by :prototype(&@) {
        my %out;
        my $block = shift;
        for (@_) {
            my $key = $block->();
            $out{$key} = $_
                unless exists $out{$key};
        }
        values %out;
    }
}


package String {
    sub get :lvalue ($string, $idx, $len = 1) {
        substr($string, $idx, $len);
    }

    sub set($string, $idx, $value) {
        get($string, $idx, length $value) = $value;
    }
}

package ColorBookKeeper {
    sub new($cls) {
        bless {
            colors => {}
        }, $cls;
    }

    sub _key($row, $col) {
        "$row:$col";
    }

    sub get($self, $row, $col) {
        return $self->{colors}->{_key $row, $col};
    }
    
    sub set($self, $row, $col, $color) {
        $self->{colors}->{_key $row, $col} = $color;
    }
}

package Input {
    use Term::ANSIColor qw(:constants);
    use overload
        '@{}' => sub($self, @ign) { $self->{data} };

    sub new($cls, $lines_ref) {
        my $max_row = $lines_ref->@*;
        my $max_col = length $lines_ref->[0];
        my $self = bless {
            data => $lines_ref,
            max_col => $max_col,
            max_row => $max_row,
            colors => ColorBookKeeper->new(),
        }, $cls;

        $self->colorfy_gears;
        $self->colorfy_gear_neighs;

        $self;
    }

    sub valid($self, $row, $col) {
        ::confess unless defined $row && defined $col;
        my $max_row = $self->@*;
        my $max_col = length $self->[0];
        0 <= $row && $row < $max_row
        && 0 <= $col && $col < $max_col;
    }

    sub get :lvalue ($self, $row, $col) {
        return undef unless valid($self, $row, $col);
        substr($self->[$row], $col, 1);
    }

    sub get_colored($self, $row, $col) {
        my $color = $self->{colors}->get($row, $col);
        my $value = $self->get($row, $col);
        $color ? ($color . $value . RESET) : $value;
    }

    sub set($self, $row, $col, $value) {
        return undef unless valid($self, $row, $col);
        get($self, $row, $col) = $value;
    }

    sub set_color($self, $row, $col, $color) {
        $self->{colors}->set($row, $col, $color);
    }
    
    sub set_colors($self, $len, $row, $col, $color) {
        $self->{colors}->set($row, $_, $color) for ($col .. $col + $len - 1)
    }

    sub get_color($self, $row, $col) {
        $self->{colors}->get($row, $col);
    }

    sub find_nums($line_str) {
        my @out;
        while ($line_str =~ /\d+/g) {
            push @out, [$&, pos($line_str) - length($&)];
        }
        \@out;
    }

    sub find_gears_line($line_str, $line) {
        my @out;
        while ($line_str =~ /\*/g) {
            push @out, { 
                match => $&, 
                col => pos($line_str) - length($&),
                row => $line 
            };
        }
        @out;
    }

    sub find_gears($self) {
        my @out;
        for (0 .. $#$self) {
            push @out, find_gears_line($self->[$_], $_);
        }
        @out;
    }

    sub neighbors($self, $row, $col, $len) {
        my @coords = (
            (map { row => $row - 1, col => $_ }, ($col - 1 .. $col + $len)),
            { row => $row, col => $col - 1},
            { row => $row, col => $col + $len},
            (map { row => $row + 1, col => $_ }, ($col - 1 .. $col + $len)),
        );
        grep { defined && $_->{char} ne "." } 
        map  { { $_->%*, char => get($self, $_->{row}, $_->{col}) } } @coords;
    }

    sub neighbors_gear($self, $gear) {
        neighbors($self, $gear->{row}, $gear->{col}, length $gear->{match})
    }

    sub find_number_next($self, $row, $col) {
        my @digits;
        my $idx = $col;
        while (::looks_like_number(my $num = $self->get($row, $idx))) {
            $idx--;
            unshift @digits, $num;
        }
        my $start = $idx + 1;
        $idx = $col + 1;
        while (::looks_like_number(my $num = $self->get($row, $idx))) {
            $idx++;
            push @digits, $num;
        }
        { digits => int(join "", @digits), row => $row, col => $start }
    }

    sub solve($self) {
        my $linum = 0;
        my $count = 0;
        my @found;
        for my $line ($self->@*) {
            my $nums = find_nums($line);
            for my $pair ($nums->@*) {
                my ($num_key, $pos) = $pair->@*;
                if (my @symbols = neighbors($self, $linum, $pos, length $num_key)) {
                    $count += $num_key;
                    push @found, "$num_key $pos";
                    say "Found $num_key, line $linum, neighbors: ", join ",", List::Util::uniq map { $_->{col} } @symbols;
                }
            }
            $linum++;
        }

        $count;

    }

    sub solve2($self) {
        say ::Dumper ::aref
        List::Util::sum
        map { $_->{ratio} }
        map { { $_->%*, 
                ratio =>
                    List::Util::product
                    map { $_->{digits} }
                    $_->{nums}->@*
            } }
        grep { $_->{nums}->@* == 2 }
        map { { $_->%*, 
                nums => ::aref
                    Array::uniq_by { $_->{digits} } 
                    map {
                        Input::find_number_next($self, $_->{row}, $_->{col}) 
                    } $_->{neighs}->@*
                } 
            }
        map { 
            gear => $_,
            neighs => ::aref 
                grep { ::looks_like_number($_->{char}) }
                neighbors_gear($self, $_), 
        },
        $self->find_gears;
    }

    sub unparse($self) {
        my @lines;
        for my $row (0 .. $self->@* - 1) {
            my @line;
            push @line, $self->get_colored($row, $_) 
                for (0 .. length($self->[$row]) - 1);
            push @lines, join "", @line;
        }
        join "\n", @lines;
    }

    sub unparse_no_color($self) {
        join "\n", $self->@*;
    }

    sub colorfy_gears($self) {
        for my $gear ($self->find_gears) {
            $self->set_color($gear->{row}, $gear->{col}, BRIGHT_RED);
        }
    }

    sub gear_neighs($self, $gear) {
        map { { $_->%*, neighs => [
                    Array::uniq_by { $_->{digits} }
                    map { $self->find_number_next($_->{row}, $_->{col}) }
                    $_->{neighs}->@*
                ] } }
        map { { $_->%*, neighs => [ 
                    grep { ::looks_like_number($_->{char}) }
                    $self->neighbors_gear($_->{gear})
                ] } }
        map { { gear => $_ } }
        $gear
    }

    sub gears_neighs($self) {
        map { { $_->%*, neighs => [
                    Array::uniq_by { $_->{digits} }
                    map { $self->find_number_next($_->{row}, $_->{col}) }
                    $_->{neighs}->@*
                ] } }
        map { { $_->%*, neighs => [ 
                    grep { ::looks_like_number($_->{char}) }
                    $self->neighbors_gear($_->{gear})
                ] } }
        map { { gear => $_ } }
        $self->find_gears;
    }

    sub gears_with_2_neighs($self) {
        grep { $_->{neighs}->@* == 2 }
        $self->gears_neighs;
    }

    sub colorfy_gear_neighs($self) {
        map { $self->set_colors(length $_->{digits},
                $_->{row}, $_->{col}, GREEN); $_ }
        map { $_->{neighs}->@* }
        $self->gears_with_2_neighs;
    }
}


my @tinput_lines = split /\n/, <<'EOF';
467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..
EOF

my $tinput = Input->new(\@tinput_lines);
$tinput->solve2;
my $input = Input->new(aref read_lines("day03.input"));
say $input->unparse;
say $input->solve2();

done_testing;
