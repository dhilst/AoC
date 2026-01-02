use v5.36;

use Carp;
use Data::Dumper;
use Time::HiRes qw(sleep);
use File::Slurper qw(read_text write_text);

sub aref { \@_ }

package String {
    sub index_all($haystack, $needle) {
        my @out;
        while ($haystack =~ /\Q$needle\E/g) {
            push @out, pos($haystack) - 1;
        }
        @out;
    }
}

package Input {
    use List::Util;
    use overload 
        '""' => \&to_str;

    package Trajectory {
        package Step {

            use overload
                '""' => sub($self, @ignored) {
                    sprintf
                        "$self->{pos} [$self->{char}] $self->{dir}",
                };

            sub new($cls, $pos, $dir, $char) {
                bless {
                    pos => $pos,
                    dir => $dir,
                    char => $char,
                }, $cls;
            }
        }

        use overload 
            '""' => sub ($self, @ignored) {
                join " => ", $self->@*,
            },
            '@{}' => sub ($self, @ignored) {
                $self->{data};
            };

        sub new($cls) {
            return bless {
                data => [],
                counter => {},
            }, $cls;
        }

        sub from_array($cls, @array){
            return bless {
                    data => \@array,
                    counter => {},
                }, $cls;
        }

        sub copy($self) {
            Trajectory->from_array($self->@*);
        }

        sub push($self, $pos, $dir, $char) {
            push $self->{data}->@*, Step->new($pos, $dir, $char);
            my $key = "$pos:$dir";
            $self->{counter}->{$key}++;
        }

        sub uniq($self) {
            List::Util::uniq map { $_->{pos} } $self->@*;
        }

        sub is_cycle($self) {
            # if we hit the same position with same direction
            # we're in a cycle
            my $max = List::Util::max values $self->{counter}->%*;
            $max > 2;
        }
    }

    package Pos {
        use overload 
            '""' => sub($self, @ignored) { 
                my ($row, $col) = $self->@*;
                sprintf "($row x $col)";
            },
            '==' => sub($self, $other, $swap) { 
                ($other, $self) = ($self, $other)
                    if $swap;
                my ($row, $col) = $self->@*;
                my ($other_row, $other_col) = $other->@*;
                $row == $other_row && $col == $other_col;
            }
            ;

        sub new($cls, $row, $col, $max_row, $max_col) {
            my $obj = bless [$row, $col, $max_row, $max_col], $cls;
            return undef unless $obj->valid;
            $obj;
        }

        sub copy($self) {
            Pos->new($self->@*);
        }
        
        sub valid($self) {
            my ($row, $col, $max_row, $max_col) = $self->@*;
            0 <= $row && $row < $max_row && 0 <= $col && $col < $max_col;
        }

        sub right($self) {
            my ($row, $col, $max_row, $max_col) = $self->@*;
            Pos->new($row, $col + 1, $max_row, $max_col);
        }

        sub left($self) {
            my ($row, $col, $max_row, $max_col) = $self->@*;
            Pos->new($row, $col - 1, $max_row, $max_col);
        }

        sub up($self) {
            my ($row, $col, $max_row, $max_col) = $self->@*;
            Pos->new($row - 1, $col, $max_row, $max_col);
        }

        sub down($self) {
            my ($row, $col, $max_row, $max_col) = $self->@*;
            Pos->new($row + 1, $col, $max_row, $max_col);
        }

        sub row($self) {
            $self->[0];
        }

        sub col($self) {
            $self->[1];
        }

        sub to_pair($self) {
            ($self->[0], $self->[1]);
        }
    }

    sub to_str($self, @ignored) {
        join "\n", "Pos: $self->{pos}", $self->{rows}->@*;
    }

    sub print($self) {
        say "$self";
        return $self;
    }

    sub new($cls, $text) {
        my @array = map { chomp; $_; } split /\n/, $text;
        my $pos = Pos->new(_find_start(\@array), scalar @array, length $array[0]);
        bless {
            rows => \@array,
            pos => $pos,
            max_row => scalar @array,
            max_col => length $array[0],
            count => 1,
            start_position => $pos->copy,
            trajectory => Trajectory->new(),
        }, $cls;
    }

    sub copy($self) {
        my @array = $self->{rows}->@*;
        my $start_position = $self->{start_position};
        my $pos = $self->{pos};
        return bless {
            rows => \@array,
            pos => Pos->new($start_position->@*),
            max_row => scalar @array,
            max_col => length $array[0],
            count => $self->{count},
            start_position => Pos->new($pos->@*),
            trajectory => $self->{trajectory}->copy,
        }
    }

    sub reset_at($self, $at, $char) {
        ::confess "invalid char $char" unless $char =~ /[v<>^]/;
        my $copy = $self->copy;
        $copy->{start_position} = $at;
        $copy->{pos} = $at;
        $copy->{count} = 1;
        $copy->set_by_pos($self->{pos}, '.');
        $copy->set_by_pos($at, $char);
        $copy;
    }

    sub find_pos($self, $square) {
        my $row_num = 0;
        my @out;
        for my $row ($self->{rows}->@*) {
            my @indexes = 
                grep { defined }
                map { Pos->new($row_num, $_, $self->{max_row}, $self->{max_col}) }
                String::index_all($row, $square);
            push @out, @indexes;
            $row_num++;
        }
        @out;
    }

    sub _find_start($rows) {
        my $i = 0;

        my ($linum, $index) =
            map { $_->{l}, $_->{i} }
            grep { $_->{i} >= 0 }
            map { l => $i++, i => index($_, "^") }, $rows->@*;
        die "start not found"
            unless defined $linum && defined $index;
            
        return ($linum, $index)
    }

    sub valid($self, %opts) {
        my @valids;
        push @valids, 0 <= $opts{col} && $opts{col} < $self->{max_col}
            if exists $opts{col};
        push @valids, 0 <= $opts{row} && $opts{row} < $self->{max_row}
            if exists $opts{row};
        List::Util::all { $_ } @valids;
    }

    sub set_by_pos($self, $pos, $value) {
        ::confess unless defined($pos);
        my ($row, $col) = $pos->@*;
        set($self, $row, $col, $value);
    }
    
    sub set($self, $row, $col, $value) {
        ::confess unless defined $row && defined $col && defined $value;
        substr($self->{rows}->[$row], $col, 1) = $value;
    }

    sub get_by_pos($self, $pos) {
        my ($row, $col) = $pos->@*;
        substr($self->{rows}->[$row], $col, 1);
    }

    sub get($self, $row, $col) {
        ::confess "invalid $row $col"
            unless defined $row
                && defined $col 
                && $self->valid(row => $row, col => $col);
        substr($self->{rows}->[$row], $col, 1);
    }

    sub get_current($self) {
        $self->get_by_pos($self->{pos});
    }

    sub move_to($self, $row, $col, $char) {
        ::confess "invalid arguments $row x $col" unless
            $self->valid(row => $row, col => $col);
        $self->set_by_pos($self->{pos}, 'X');
        $self->set($row, $col, $char);
        $self->{pos} = Pos->new($row, $col, $self->{max_row}, $self->{max_col});
    }

    sub turn_right($self) {
        my $current = $self->get_current;
        my $new = sub {
            if ($current eq "^") {
                return ">";
            } elsif ($current eq ">") {
                return "v";
            } elsif ($current eq "v") {
                return "<";
            } elsif ($current eq "<") {
                return "^";
            } else {
                die "invalid square $current";
            }
        }->();
        $self->set_by_pos($self->{pos}, $new);
    }

    sub put_box($self) {
        my $pos = $self->{pos};
        my $dir = $self->get_current;
        my $box_pos = sub {
            if ($dir eq "^") {
                return $pos->up;
            } elsif ($dir eq ">") {
                return $pos->right;
            } elsif ($dir eq "v") {
                return $pos->down;
            } elsif ($dir eq "<") {
                return $pos->left;
            } else {
                ::confess "invalid dir $dir";
            }
        }->();
        return undef unless defined($box_pos);
        $self->set_by_pos($box_pos, "O");
        $box_pos;
    }

    sub put_box_at($self, $row, $col) {
        ::confess "trying to put a box above other object at $row, $col\n$self"
            unless $self->get($row, $col) =~ /[\.]/;
        $self->set($row, $col, "O")
    }

    sub calc_step($self) {
        my $current = $self->get_current;
        my ($row, $col) = $self->{pos}->@*;
        if ($current eq "^") {
            $row--;
        } elsif ($current eq "v") {
            $row++;
        } elsif ($current eq ">") {
            $col++;
        } elsif ($current eq "<") {
            $col--;
        } else {
            ::confess "Invalid direction $current";
        }

        my $pos = Pos->new($row, $col, $self->{max_row}, $self->{max_col});
        return undef unless defined $pos;
        return undef unless $self->get_by_pos($pos) =~ /[\.X]/;
        return $pos;
    }

    sub step($self, $hit_cb = undef) {
        my $current = $self->get_current;
        my ($row, $col) = $self->{pos}->@*;
        if ($current eq "^") {
            $row--;
        } elsif ($current eq "v") {
            $row++;
        } elsif ($current eq ">") {
            $col++;
        } elsif ($current eq "<") {
            $col--;
        } else {
            ::confess "Invalid direction $current\n$self";
        }
        my $is_valid = $self->valid(row=>$row, col=>$col);
        return undef unless $is_valid;
        my $new_square = $self->get($row, $col);
        if ($new_square eq ".") {
            $self->{count}++;
            $self->move_to($row, $col, $current);
        } elsif ($new_square eq "X") {
            $self->move_to($row, $col, $current);
        } elsif ($new_square eq "#" || $new_square eq "O") {
            local $_ = $self;
            $self->turn_right;
        } else {
            die "Invalid square $new_square, current=$current";
        }
        $self->{trajectory}->push($self->{pos}, $self->get_current, $new_square);
        return undef if defined $hit_cb && !$hit_cb->($self);
        ::sleep $ENV{SLEEP} if $ENV{SLEEP};
        return $self;
    }

    sub step_while($self, $hit_cb) {
        while ($self->step($hit_cb)) {};
    }
    
    sub solve($self) {
        while ($self->step) {};
        return $self->{count};
    }
}

package main;

my $FOO = <<"EOF";
..........
..........
.........2
...^......
..1.......
........3.
..........
..........
..........
..........
EOF

my $test_text = <<"EOF";
....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...
EOF

my $tinput = Input->new($test_text);

say $tinput;

sub find_loop($input, $row, $col) {
    my $pos = Pos->new($row, $col, $input->{max_row}, $input->{max_col});
    return 0 if $input->get_by_pos($pos) ne ".";
    my $copy = $input->reset_at($input->{pos}, $input->get_current);
    $copy->put_box_at($row, $col);

    my $max_steps = $ENV{MAX_STEPS} // 10_000;
    $copy->step_while(sub {
            $copy->print if $max_steps % 100 == 0 || $ENV{SLEEP};
            $max_steps-- > 0 && !$copy->{trajectory}->is_cycle;
        });
    die "increase MAX_STEPS" if $max_steps <= 0;
    return $copy->{trajectory}->is_cycle;
}

sub find_all_bruteforce($input) {
    my @loops; 
    while ($input->step) {
        $input->print;
        my $next_pos = $input->calc_step;
        next unless defined $next_pos;
        say "Next ", $input->get_by_pos($next_pos);
        if (find_loop($input, $next_pos->to_pair)) {
            say "LOOP found $next_pos!";
            push @loops, $next_pos;
        }
    }
    @loops;
}
# say find_loop($tinput, 6, 3);
say join "\n", find_all_bruteforce($tinput);

# $tinput->print;
# say $tinput->reset_at($box->down, "^");
# say $tinput->reset_at($box->left, ">");

exit 0 if $ENV{SKIP};
my $input = Input->new(read_text("day06.input"));
say $input->{start_position};
my @loops =  find_all_bruteforce($input);
write_text("day06-loops.txt", join "\n", @loops);
say "day06-loops.txt written";
