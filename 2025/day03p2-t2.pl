use warnings;
use strict;
use feature 'say';
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Test::More;
use File::Slurper qw(read_lines);
use Parallel::ForkManager;


package Bat;

use Class::Struct;
use List::Util;
use Term::ANSIColor qw(:constants);
use Carp;
use Time::HiRes qw(sleep);

use overload
    '""' => \&stringify,
    ;

struct(
    batteries => '@',
    state => '@',
    max => '$',
);

sub make {
    my ($batteries, $max) = @_;

    $batteries = [ split //, $batteries ]
        unless (ref($batteries) eq "ARRAY");

    my @state = map { 1 } 0 .. $max - 1;
    push @state, 0 while @state < $batteries->@*;
    
    croak "invalid arguments"
        unless $batteries && $max && $max < $batteries->@*;
    return Bat->new(
        batteries => $batteries,
        state => \@state,
        max => $max,
    );
}

our ($state, $power, $index);
sub map(&$) {
    my ($block, $self) = @_;
    my @out;
    for my $i (0 .. $#{$self->batteries}) {
        local $power = $self->batteries->[$i];
        local $state = $self->state->[$i];
        local $index = $i;
        push @out, $block->($power, $state, $i);
    }
    return @out;
}

sub stringify {
    my ($self) = @_;
    my $last_color = "";
    my $color = sub {
        my $newcolor = $state ? GREEN : RED;
        if ($newcolor ne $last_color) {
            $last_color = $newcolor;
            return $newcolor;
        }
        return "";
    };

    my @out = Bat::map { $color->&* . $power } $self;
    return join "", @out, RESET;
}

sub print {
    my ($self) = @_;
    say $self;
    return $self;
}

sub value {
    my ($self) = @_;
    my $string = join "", Bat::map { $state ? $power : "" } $self;
    return int($string);
}

sub swap {
    my ($self, $a, $b) = @_;
    my $a_state = $self->state->[$a];
    my $b_state = $self->state->[$b];
    return $self if $a_state == $b_state;
    my @state_copy = $self->state->@*;
    $state_copy[$a] = $b_state;
    $state_copy[$b] = $a_state;
    return Bat->new(
        batteries => $self->batteries,
        state => \@state_copy,
        max => $self->max,
    );
}


package main;

my @bats = map { Bat::make($_, 12) } read_lines "day03.input"; 

my $max = $bats[0]->batteries->@*;
my @maxes;
my $maxtries = $ARGV[0] // 1000;

my $pm = Parallel::ForkManager->new(`nproc --all`);
$pm->run_on_finish(sub {
    my ($pid, $exit, $ident, $signal, $dump, $data) = @_;
    if ($exit == 0) {
        push @maxes, $data->[0];
    }
});

for my $bat (@bats) {
    $pm->start and next;
    my $obj = $bat;
    my $lastchange = time;
    my $timeout = 16;
    while (time - $lastchange < $timeout) {
        my $index_0 = int(rand($max));
        my @other_indexes = map { int(rand($max)); } (0 .. $max - 1);
        my $copy = 
            List::Util::reduce { $a->value > $b->value ? $a : $b }
            map { $obj->swap($index_0, $_); }
            @other_indexes;
        if ($copy->value > $obj->value) {
            $obj = $copy;
            $obj->print;
            $lastchange = time;
            next;
        }
    }

    $pm->finish(0, [ $obj->value ]);
}
$pm->wait_all_children;


say "Solution: ", List::Util::sum @maxes;

# is_deeply($bat->left(4), ['0' .. '3']);
# is_deeply($bat->right(4), [ '4' .. '9' ]);




done_testing;
