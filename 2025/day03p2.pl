#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use Test::More;
use Data::Dumper qw(Dumper);
use List::Util qw();
use Carp qw(croak);
use Term::ANSIColor qw(:constants);

package Digits ;

sub from {
    return [ split //, $_[0] ];
}

sub join {
    my ($digits) = @_;
    ::croak "undefined digits" if !defined($digits);
    return "" if $digits->@* == 0;
    return join '', $_[0]->@*;
}

package Array;

use Test::More;

sub index {
    my ($arrayref, $num) = @_;
    for (my $i = 0; $i < $arrayref->@*; $i++) {
        return $i if $arrayref->[$i] eq $num;
    }
    return -1;
}

sub pop_at {
    my ($arrayref, $idx) = @_;
    return splice $arrayref->@*, $idx, 1;
}

sub push_at {
    my ($arrayref, $idx, $element) = @_;
    splice $arrayref->@*, $idx, 1, $element;
    return;
}

sub remove_first {
    my ($arrayref, $ele) = @_;
    my $index = Array::index($arrayref, $ele);
    pop_at($arrayref, $index)
        if $index != -1;
    return $arrayref;
}

sub split_at {
    my ($arrayref, $pos) = @_;
    return ( 
        [ @$arrayref[0 .. $pos - 1] ], 
        [ @$arrayref[$pos .. $#$arrayref] ],
    );
}

is_deeply(Array::pop_at([1,2,3], 0), 1);
is_deeply(Array::remove_first([1,2,3], 2), [1,3]);

package Bat;

use Term::ANSIColor qw(:constants);

sub new {
    my ($cls, $num, $max) = @_;
    $max //= 12;
    my $digits  = Digits::from($num);
    my $self = {
        digits => $digits,
        on => [ 0 .. $max - 1],
        available => [ $max .. $#$digits ],
        off => [ ],
        max => $max,
        index => 0,
    };

    return bless $self, $cls;
}

sub print {
    my ($self) = @_;
    for (my $i = 0; $i < $self->{digits}->@*; $i++) {
        if (Array::index($self->{on}, $i) != -1) {
            print GREEN;
        } elsif (Array::index($self->{off}, $i) != -1) {
            print RED;
        } elsif (Array::index($self->{available}, $i) != -1) {
            print YELLOW;
        } else {
            print BLUE;
        }
        print $self->{digits}->[$i];
    }
    print RESET, "\n"; 
    return $self;
}

sub print_index {
    my ($self) = @_;
    print " " x $self->{index}, "^\n";
    return $self;
}

sub print_line {
    my ($self) = @_;
    say "-" x $self->{digits}->@*;
    return $self;
}

sub print_swap {
    my ($self, $off, $on) = @_;
    say " " x $off, "-", " " x ($on - $off - 1), "+";
    return $self;
}

sub last_greater_available_index {
    my ($self, $start) = @_;
    $start //= 0;

    my @available = $self->{available}->@*;
    shift @available
        while (@available && $start > $available[0]);

    return -1 if @available == 0;

    my $max = $self->get($available[0]);
    my $index = $available[0];
    for my $i (@available) {
        my $value = $self->get($i);
        if ($value >= $max) {
            $max = $value;
            $index = $i;
        }
    }
    return $index;
}

sub next_on_after {
    my ($self, $after) = @_;
    for (my $i = $after + 1; $i < $self->{digits}->@*; $i++) {
        return ($self->get($i), $i) if
            Array::index($self->{on}, $i) != -1
    }

    return undef;
}

sub is_on {
    my ($self, $idx) = @_;
    return Array::index($self->{on}, $idx) != -1;
}

sub is_available {
    my ($self, $idx) = @_;
    return Array::index($self->{available}, $idx) != -1;
}

sub swap {
    my ($self, $off, $on) = @_;
    ::croak "invalid off: $off or on: $on"
        unless $off < $on 
            && $off >= 0
            && $off < $self->{digits}->@*
            && $on  < $self->{digits}->@*
            && $on  < $self->{digits}->@*;

    ::croak "invalid move: turn off $off, is not on:\n", ::Dumper($self)
        unless $self->is_on($off);
    ::croak "invalid move: turn on $on, is not available"
        unless $self->is_available($on);

    $self->print()
        ->print_swap($off, $on);

    
    Array::remove_first($self->{on}, $off);
    Array::remove_first($self->{available}, $on);
    push $self->{off}->@*, $off;
    push $self->{on}->@*, $on;

    $self->print();

    return $self;
}

sub get {
    my ($self, $idx) = @_;
    ::croak "Invalid index $idx"
        if $idx > $self->{digits}->@*;
    return $self->{digits}->[$idx];
}

sub first_on {
    my ($self) = @_;
    ::croak "No switches on"
        unless $self->{on}->@* > 0;

    return $self->get($self->{on}->[0]);
}

sub step {
    my ($self) = @_;
    
    my $start_idx = $self->{index};

    $self->print_line();
    say "step $self->{index}";
    $self->print()->print_index();

    $self->{index}++
        until ($self->{index} >= $self->{digits}->@*)
            || $self->is_on($self->{index});
 
    if ($self->{index} > $self->{digits}->@*
        || $self->{available}->@* == 0) {
        say "Reached end";
        $self->print()->print_index()->print_line();
        return $self;
    }

    my $current_idx = $self->{index};
    my $current = $self->get($current_idx);
    my ($next, $next_idx) = $self->next_on_after($current_idx);
    if (!defined $next) {
        my $last_greater_available_idx = $self->last_greater_available_index($current_idx);

        if ($last_greater_available_idx == -1) {
            say "next_on_after failed last available not found";
            $self->print_line();
            $self->{index}++;
            return $self;
        }

        my $last_greater_available = $self->get($last_greater_available_idx);
        if ($last_greater_available > $current) {
            $self->swap($current_idx, $last_greater_available_idx);
            say "step 1 $start_idx -> $self->{index}";
            $self->print_line();
            $self->{index}++;
            return $self;
        }

        $self->{index}++;
        return $self;
    }

    if ($next > $current) {
        my $last_greater_available_idx = $self->last_greater_available_index();
        if ($last_greater_available_idx <= $current_idx) {
            say "last_greater_available_idx before current_idx";
            $self->print_line();
            return $self;
        }
        $self->swap($current_idx, $last_greater_available_idx);
        $self->{index}++;

        say "step 2 $start_idx -> $self->{index}";
        $self->print_line();
        return $self;
    }

    say "current=$current > next=$next";
    $self->print_line();
    $self->{index}++;

    return $self;
}


package main;


# my $bat = Bat->new(234234234234278);
# is($bat->last_greater_available_index, 14);
# is_deeply ([ $bat->next_on_after(0) ], [3, 1]);
# $bat->print;
# $bat->swap(0, 12);
# $bat->print;
# $bat->swap(1, 13);
# $bat->print;
# is_deeply([ $bat->next_on_after(0) ], [4, 2]);

# my $bat = Bat->new(234234234234278, 2);
my $bat = Bat->new(234234234294231, 2);
$bat->print()
    ->print_index()
    ->step()
    ->step()
    ->step()
    ->step()
    ->step()
    ;




done_testing;
