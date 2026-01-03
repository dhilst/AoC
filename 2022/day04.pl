use v5.10;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use List::Util;
use Test::More;
use File::Slurper qw(read_text);
use Term::ANSIColor qw(:constants);
use Time::HiRes;

sub aref { \@_ }

package Array {
    sub product {
        my ($array_a, $array_b) = @_;
        map {
            my $value_a = $_;
            map [ $value_a, $_ ], @$array_b;
        } @$array_a;
    }
}

package Join {
    sub concat { join "", @_; }
    sub spaces { join " ", @_; }
}

package Board {
    use overload
        '""' => \&to_str;

    sub new {
        my $cls = shift;
        my @rows;
        for my $line (split /\n/, $_[0]) {
            chomp $line;
            my @nums;
            push @nums, int($&) while $line =~ /\d+/g;
            push @rows, \@nums;
        }
        my $max_row = @rows;
        my $max_col = $#{$rows[0]} + 1;
        my %lookup_hash;
        my @coords = Array::product [0 .. $max_row - 1], [0 .. $max_col - 1];
        for (@coords) {
            my ($row, $col) = @$_;
            $lookup_hash{$rows[$row]->[$col]} = [ $row, $col ];
        }

        bless {
            rows => \@rows,
            max_row => $max_row,
            max_col => $max_col,
            marked => {},
            lookup_hash => \%lookup_hash,
        }, $cls;
    }

    sub get {
        my ($self, $row, $col) = @_;
        ::confess unless
            0 <= $row && $row < $self->{max_row}
            && 0 <= $col && $col < $self->{max_col};
        $self->{rows}->[$row]->[$col];
    }

    # return the coordinate [ row, col ] of the value
    # or undef if not found
    sub lookup_value {
        my ($self, $value) = @_;
        return undef unless
            exists $self->{lookup_hash}->{$value};

        @{ $self->{lookup_hash}->{$value} };
    }

    sub row {
        my $self = shift;
        my $row = shift;
        @{ $self->{rows}->[$row] };
    }

    sub col {
        my ($self, $col) = @_;
        ::confess "invalid argument" unless defined $col;
        my @col;
        for my $row_idx (0 .. $self->{max_row} - 1) {
            push @col, ($self->row($row_idx))[$col];
        }
        @col
    }

    sub mark  {
        my ($self, $row, $col) = @_;
        ::confess "invalid argument" unless defined $col && defined $row;
        $self->{marked}->{"${row}x$col"}++;
    }
    
    sub is_marked {
        my ($self, $row, $col) = @_;
        exists $self->{marked}->{"${row}x$col"};
    }

    sub is_row_marked {
        my ($self, $row) = @_;
        my @cols = (0 .. $self->{max_col} - 1);
        List::Util::all { $self->is_marked($row, $_) } @cols;
    }

    sub is_col_marked {
        my ($self, $col) = @_;
        my @rows = (0 .. $self->{max_row} - 1);
        List::Util::all { $self->is_marked($_, $col) } @rows;
    }

    sub has_win {
        my ($self) = @_;
        for my $row (0 .. $self->{max_row} - 1) {
            return 1 if $self->is_row_marked($row);
        }
        for my $col (0 .. $self->{max_col} - 1) {
            return 1 if $self->is_col_marked($col);
        }
        return 0;
    }
    
    sub to_str {
        my ($self) = @_;
        my $buf = "";
        for my $row (0 .. $self->{max_row} - 1) {
            for my $col (0 .. $self->{max_col} - 1) {
                $buf .= ::BRIGHT_RED
                    if $self->is_marked($row, $col);
                $buf .= sprintf "%2d", $self->get($row, $col);
                $buf .= ::RESET;
                $buf .= " ";
            }
            $buf .= "\n";
        }
        $buf;
    }
    
    sub score {
        my ($self, $round_number) = @_;
        ::confess "invalid argument" unless defined $round_number;
        my @rows = (0 .. $self->{max_row} - 1);
        my @cols = (0 .. $self->{max_col} - 1);
        my @unmarked =
            map {
                my ($row, $col) = @$_;
                $self->get($row, $col);
            }
            grep {
                my ($row, $col) = @$_;
                ! $self->is_marked($row, $col);
            }
            Array::product \@rows, \@cols;
        my $sum = List::Util::sum(@unmarked);
        ::confess "invalid board" unless defined $sum;
        $sum * $round_number;
    }
}

my $board = Board->new(<<'EOF');
14 21 17 24  4
10 16 15  9 19
18  8 23 26 20
22 11 13  6  5
 2  0 12  3  7
EOF

$board->mark(0, $_) for (0 .. 4);
$board->mark(1, 3);
$board->mark(2, 2);
$board->mark(3, 1);
$board->mark(3, 4);
$board->mark(4, 0);
$board->mark(4, 1);
$board->mark(4, 4);
say "to_str: ", $board->to_str;
# say Dumper $board->has_win;
say "score: ", $board->score(24);
say "lookup: ", Dumper [ $board->lookup_value(99) ];
# say $board->to_str;
# say Dumper Join::spaces $board->col(0);
# say Dumper Join::spaces $board->row(0);

my $text = <<'EOF';
7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1

22 13 17 11  0
 8  2 23  4 24
21  9 14 16  7
 6 10  3 18  5
 1 12 20 15 19

 3 15  0  2 22
 9 18 13 17  5
19  8  7 25 23
20 11 10 24  4
14 21 16 12  6

14 21 17 24  4
10 16 15  9 19
18  8 23 26 20
22 11 13  6  5
 2  0 12  3  7
EOF

package Input {
    use overload
        '""' => \&to_str;
    sub new {
        my ($cls, $text) = @_;
        my @lines = split /\n/, $text;
        my @balls = map int, split /,/, shift @lines;
        shift @lines; #skip empty line

        my @boards;
        my $board_lines;
        for my $line (@lines) {
            chomp $line;

            if ($line =~ /^$/) {
                push @boards, Board->new($board_lines);
                $board_lines = "";
                next;
            }

            $board_lines .= "$line\n";
        }
        push @boards, Board->new($board_lines);

        bless {
            balls => \@balls,
            boards => \@boards,
            balls_played => [],
            winner_boards => [],
        }, $cls;
    }

    sub to_str {
        my ($self) = @_;
        sprintf "%s\n\n%s",
            join(",", @{$self->{balls}}),
            join("\n\n", map { $_->to_str } @{$self->{boards}})
            ;
    } 

    sub play_one_ball {
        my ($self) = @_;
        ::confess "no more balls to play"
            unless @{ $self->{balls} } > 0;
        my $ball = shift @{ $self->{balls} };
        say "Playing $ball";

        for my $board_idx (0 .. $#{ $self->{boards} }) {
            my $board = $self->{boards}->[$board_idx];
            my ($row, $col) = $board->lookup_value($ball);
            next unless defined $row;

            $board->mark($row, $col);
        }
        push @{ $self->{balls_played} }, $ball;

        my $first_winner = undef;
        for my $board_idx (0 .. $#{ $self->{boards} }) {
            my $board = $self->{boards}->[$board_idx];
            next unless defined $board;
            if ($board->has_win()) {
                splice @{ $self->{boards} }, $board_idx, 1;
                push @{ $self->{winner_boards} }, $board;
                say "Winner [#$board_idx] ($ball) !\n$board";
                say "Boards remainig ", scalar @{ $self->{boards} };
                $first_winner = $board unless defined $first_winner;
            }
        }
        return $first_winner->score($ball) if defined $first_winner;
        undef;
    }

    sub play_all_balls {
        my ($self) = @_;
        my $score;
        until ($score = $self->play_one_ball()) {
            say $self;
        }
        $score;
    }

    sub play_all_balls_p2 {
        my ($self) = @_;
        my $score;
        while (1) {
            $score = $self->play_one_ball();
            if (@{ $self->{boards} } == 0) {
                return $score;
            }
            Time::HiRes::sleep($ENV{SLEEP} // 0.3)
            
        }
        die "oops (should never happen)";
    }
}

my $tinput = Input->new($text);
say $tinput;
# say $tinput->play_all_balls;
# # # # # # say Input->new($text)->play_all_balls_p2;
# say Input->new(read_text("day04.input"))->play_all_balls;
say Input->new(read_text("day04.input"))->play_all_balls_p2;
