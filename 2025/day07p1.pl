use strict;
use warnings;
use feature 'say';

use Data::Dumper;
use Carp;
use File::Slurper qw(read_lines);

sub aref { \@_; }
sub dref { $_[0]->@*; }

package Input;

use Term::ANSIColor qw(:constants);

use overload
    '""' => \&stringify;


sub parse {
    map [ split //, $_ ], @_;
}

sub new {
    my $cls = shift;
    bless {
        data => [ parse @_ ],
        max_row => scalar @_,
        max_col => length $_[0],
    }, $cls;
}

sub stringify {
    my ($self) = @_;
    my $colorfy = sub {
        return RED . "^" if /\^/; 
        return GREEN . "|" if /\|/;
        return RESET . ".";
    };
    join "\n", map { join "", map { $colorfy->() } $_->@* } $self->{data}->@*;
}

sub _valid_row_col {
    my ($self, $row, $col) = @_;
    $row >= 0 
        && $row < $self->{max_row}
        && $col >= 0
        && $col < $self->{max_col};
}

sub get {
    my ($self, $row, $col) = @_;
    return unless $self->_valid_row_col($row, $col);
    $self->{data}->[$row]->[$col];
}

sub set {
    my ($self, $row, $col, $value) = @_;
    return unless $self->_valid_row_col($row, $col);
    $self->{data}->[$row]->[$col] = $value;
}

sub find_all {
    my ($self, $row_index, $char) = @_;
    ::confess "invalid argument" unless
        $self->_valid_row_col($row_index, 0);
    my @out;
    for my $col_index (0 .. $self->{data}->[$row_index]->@* - 1) {
        my $col = $self->{data}->[$row_index]->[$col_index];
        if ($char eq $col) {
            push @out, $col_index;
        }
    }
    wantarray ? @out : $out[0];
}

sub print {
    my ($self) = @_;
    say "-" x $self->{max_col};
    say $self;
    say "-" x $self->{max_col};
}

sub step {
    my ($self, $row, $col, $split) = @_;
    my $value = $self->get($row, $col);
    if ($value eq ".") {
        $self->set($row, $col, "|");
        return ($col,);
    } elsif ($value eq "^") {
        $self->set($row, $col - 1, "|");
        $self->set($row, $col + 1, "|");
        $$split++ if defined($split);
        return grep { $self->_valid_row_col($row, $_) } $col - 1, $col + 1;
    } elsif ($value eq "|") {
        return ();
    }

    ::confess "invalid cell $value";
}


sub play {
    my ($self) = @_;
    my $start = $self->find_all(0, "S");
    my $split = 0;
    my @next = $self->step(1, $start, \$split);
    $self->print;
    for (my $row = 2; $row < $self->{max_row}; $row += 1) {
        @next = map { $self->step($row, $_, \$split) } @next;
        $self->print;
    }

    return $split;
}
package main;



my @test_input = split /\n/, <<"EOF";
.......S.......
...............
.......^.......
...............
......^.^......
...............
.....^.^.^.....
...............
....^.^...^....
...............
...^.^...^.^...
...............
..^...^.....^..
...............
.^.^.^.^.^...^.
...............
EOF

my $test_input = Input->new(@test_input);
# $test_input->print;
say $test_input->play;


my $input = Input->new(read_lines("day07.input"));
say $input->play;

