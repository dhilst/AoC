use strict;
use warnings;
use feature 'state';
use feature 'say';

no autovivification;

use Data::Dumper;
use Carp;
use File::Slurper qw(read_lines);
use List::Util;

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

sub stringify_row {
    my ($self, $row ) = @_;
    ::confess "invalid row $row" unless $row >= 0 && $row < $self->{max_row};
};

sub colorfy {
    state @other_colors = (BRIGHT_GREEN, BRIGHT_YELLOW, BRIGHT_RED, BRIGHT_MAGENTA, BRIGHT_BLUE, BRIGHT_CYAN, WHITE);
    return RESET . "^" if $_ =~ /\^/; 
    return GREEN . "|" if $_ =~ /\|/;
    return RESET . "S" if $_ =~ /S/;
    return " " if $_ =~ /\./;
    my $i = (length $_) - 1;
    my ($left_digit) = $_ =~ /^(\d)/;
    die unless defined $left_digit;
    return $other_colors[$i % @other_colors] . $left_digit;
};

sub stringify {
    my ($self) = @_;
    join "\n", 
        (map { join "", map colorfy, $_->@* } $self->{data}->@*),
        RESET;
}

sub stringify_row {
    my ($self, $row) = @_;
    ::confess "invalid row $row"
        unless 0 <= $row && $row < $self->{max_row};

    return map colorfy, $self->{data}->[$row]->@*;
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
    for (my $col_index = 0; $col_index <= $self->{data}->[$row_index]->@* - 1; $col_index++) {
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

sub print_row {
    my ($self, $row) = @_;
    say $self->stringify_row($row);
}

sub step {
    my ($self, $row, $col, $split) = @_;
    my $value = $self->get($row, $col);
    my %out;
    if ($value eq ".") {
        $out{$col}++;
    } elsif ($value eq "^") {
        $$split += 1;
        my $max_col = $self->{max_col};
        $out{$_}++ for grep { 0 <= $_ && $_ <= $max_col } $col - 1, $col + 1;
    }

    return \%out;
}

sub dump_href {
    my $href = shift;
    my $buf = "{ ";
    for (sort { int($a) <=> int($b) } keys $href->%*) {
        $buf .= "$_=$href->{$_}, "
    }
    $buf =~ s/, $//;
    $buf .= " }";
    return $buf;
}

sub step_row {
    my $self = shift;
    my $row = shift;
    my $split = shift;
    my $cols_href = shift;
    my $max_col = $self->{max_col};
    
    # say "next ", dump_href($cols_href);
    my %out;
    for my $col (sort { $a <=> $b } keys $cols_href->%*) {
        my $value = $self->get($row, $col);
        if ($value eq ".") {
            $out{$col} += exists $cols_href->{$col} ? $cols_href->{$col} : 1;
            next;
        } elsif ($value eq "^") {
            $$split += $cols_href->{$col};
            # say "SPLIT! = $$split at ($row x $col) (count $cols_href->{$col})";
            $out{$_} +=  $cols_href->{$_} // 0 + exists $cols_href->{$col} ? $cols_href->{$col} : 1
                for grep { 0 <= $_ && $_ <= $max_col } $col - 1, $col + 1;
            next;
        } elsif ($value eq "|" || $value =~ /\d+/) {
            die "never happen";
        }
        ::confess "invalid cell $value";
    }
    # say "rslt ", dump_href(\%out);

    \%out;
}

sub play {
    my ($self) = @_;
    my $start = $self->find_all(0, "S");
    my $split = 1;
    $self->print_row(0);
    my $cols_href = $self->step(1, $start, \$split);
    $self->set(1, $_, '1') for keys $cols_href->%*;
    $self->print_row(1);
    for (my $row = 2; $row < $self->{max_row}; $row += 1) {
        $cols_href = $self->step_row($row, \$split, $cols_href);
        $self->set($row, $_, $cols_href->{$_}) for keys $cols_href->%*;
        $self->print_row($row);
    }

    List::Util::sum values $cols_href->%*;
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
$test_input->print;
say $test_input->play;


my $input = Input->new(read_lines("day07.input"));
say $input->play;

