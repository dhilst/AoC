use strict;
use warnings;
use feature 'say';

use Data::Dumper;
use List::Util;
use Carp;
use Test::More;
use Term::ANSIColor qw(:constants);
use File::Slurper qw(read_lines);

my $iota = 0;
use constant {
    UP => $iota++,
    DOWN => $iota++,
    LEFT => $iota++,
    RIGTH => $iota++,
    UP_LEFT => $iota++,
    UP_RIGHT => $iota++,
    DOWN_LEFT => $iota++,
    DOWN_RIGHT => $iota++,
};

sub DIRECTIONS {
    return (
        UP,
        DOWN,
        LEFT,
        RIGTH,
        UP_LEFT,
        UP_RIGHT,
        DOWN_LEFT,
        DOWN_RIGHT
    );
}

sub enumerate {
    my $i = 0;
    return map { [ $i++, $_ ] } @_;
}

package Input;
use overload
    '""' => \&stringify;

# static method

sub map (&$) {
    my ($block, $self) = @_;
    my @out;
    for my $row_pair (::enumerate $self->{m}->@*) {
        my ($ir, $row) = $row_pair->@*;
        for my $col_pair (::enumerate $row->@*) {
            my ($ic, $col) = $col_pair->@*;
            push @out, $block->($ir, $ic, $self);
        }
    }
    return @out;
}

sub new {
    my ($cls, @m) = @_;
    my @data = map [ split //, $_ ], @m;
    my $max_row = @data;
    my $max_col = $data[0]->@*;
    return bless {
        m => \@data,
        max_row => $max_row,
        max_col => $max_col 
    }, $cls;
}

# instance methods

sub stringify {
    my ($self) = @_;
    my $last_color = ::RESET;
    my %color_map = (
        '.' => ::RESET,
        '@' => ::GREEN,
        'x' => ::RED,
    );
    my @lines;
    for my $row (0 .. $self->{max_row}) {
        my $line = join "", map {
            my $value = $_;
            my $buf = "";
            my $new_color = $color_map{$value};
            if ($new_color ne $last_color) {
                $buf .= $new_color;
                $last_color = $new_color;
            }
            $buf .= $value;
        } $self->{m}->[$row]->@*;
        push @lines, $line;
    }
    return join "\n", @lines;
}

sub _valid_row_col {
    my ($self, $nrow, $ncol) = @_;
    return $nrow >= 0 && $nrow < $self->{max_row} &&
            $ncol >= 0 && $ncol < $self->{max_col};
}

sub get {
    my ($self, $row, $col) = @_;
    return undef
        unless $self->_valid_row_col($row, $col);
    return $self->{m}->[$row]->[$col];
}

sub set {
    my ($self, $row, $col, $value) = @_;
    ::confess 
        unless $self->_valid_row_col($row, $col);
    $self->{m}->[$row]->[$col] = $value;
}

sub get_neighbor_pos {
    my ($self, $row, $col, $direction) = @_;
    ::confess "invalid row col"
        unless $self->_valid_row_col($row, $col);
    if ($direction == ::UP) {
        return ($row - 1, $col);
    } elsif ($direction == ::DOWN) {
        return ($row + 1, $col);
    } elsif ($direction == ::LEFT) {
        return ($row, $col - 1);
    } elsif ($direction == ::RIGTH) {
        return ($row, $col + 1);
    } elsif ($direction == ::UP_LEFT) {
        return ($row - 1, $col - 1);
    } elsif ($direction == ::UP_RIGHT) {
        return ($row - 1, $col + 1);
    } elsif ($direction == ::DOWN_LEFT) {
        return ($row + 1, $col - 1);
    } elsif ($direction == ::DOWN_RIGHT) {
        return ($row + 1, $col + 1);
    } else {
        ::confess "Invalid direction: $direction";
    }
}

sub get_neighbor {
    my ($self, $row, $col, $direction) = @_;
    my ($nrow, $ncol) = $self->get_neighbor_pos($row, $col, $direction);
    return undef
        unless $self->_valid_row_col($nrow, $ncol);
    return $self->get($nrow, $ncol), $nrow, $ncol;
}

sub get_neighbors {
    my ($self, $row, $col) = @_;
    my @neighs =
        grep { defined $_->[0] }
        map { [ $self->get_neighbor($row, $col, $_) ] }
        ::DIRECTIONS;
    return \@neighs;
}

sub get_neighbors_count {
    my ($self, $row, $col) = @_;
    my $count = 0;
    for ($self->get_neighbors($row, $col)->@*) {
        my ($neigh, $nrow, $ncol) = $_->@*;
        # say "neigh $neigh $nrow $ncol";
        $count++ if $neigh eq '@';
    }
    return $count;
}

sub remove_paper_roll {
    my ($self, $row, $col) = @_;
    ::confess unless $self->_valid_row_col($row, $col);
    my $value = $self->get($row, $col);
    return unless $value eq '@';
    $self->set($row, $col, 'x');
}

package main;

sub play_one_round {
    my ($input) = @_;
    my $count = 0;
    my @remove =
        grep { defined }
        Input::map sub {
            my ($row, $col, $self) = @_;
            my $value = $self->get($row, $col);
            return undef if $value ne '@';
            my $n_count = $self->get_neighbors_count($row, $col);
            return undef if $n_count >= 4;
            $count++;
            return [ $row, $col ];
        }, $input;

    for (@remove) {
        my ($row, $col) = $_->@*;
        $input->remove_paper_roll($row, $col);
    }

    return $count;
}

my @test_input = split /\n/, <<"EOF";
..@@.@@@@.
@@@.@.@.@@
@@@@@.@.@@
@.@@@@..@.
@@.@@@@.@@
.@@@@@@@.@
.@.@.@.@@@
@.@@@.@@@@
.@@@@@@@@.
@.@.@@@.@.
EOF


my $obj = Input->new(@test_input);

# say $obj->get(0, 2);
# say Dumper [ $obj->get_neighbor_pos(0, 0, DOWN) ];
# is($obj->get_neighbors_count(0, 0), 2);

# done_testing;


my $total = 0;
while ((my $count = play_one_round($obj)) > 0) {
    say $obj;
    say "Removed: $count";
    say "-" x 10;
    $total += $count;
}
say "Solution: $total";



my $input = Input->new(read_lines("day04.input"));
$total = 0;
while ((my $count = play_one_round($input)) > 0) {
    say $input;
    say "-" x $input->{max_col};
    $total += $count;
}
say "Solution: $total";
