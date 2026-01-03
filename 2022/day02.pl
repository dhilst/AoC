use v5.10;
use strict;
use warnings;

use Data::Dumper;
use File::Slurper qw(read_text);

package Input {
    sub parse {
        my ($cls, $text) = @_;
        my @commands;
        for (split /\n/, $text) {
            /(forward|down|up) (\d+)/
                or die "invalid line $_";
            push @commands, { cmd => $1, distance => int($2) };
        }
        bless {
            commands => \@commands,
            horizontal => 0,
            depth => 0,
            aim => 0,
            done => [],
        }, $cls;
    }

    sub do_one_command() {
        my ($self) = @_;
        my $cmd = shift @{ $self->{commands} };
        if ($cmd->{cmd} eq "forward") {
            $self->{horizontal} += $cmd->{distance};
        } elsif ($cmd->{cmd} eq "down") {
            $self->{depth} += $cmd->{distance};
        } elsif ($cmd->{cmd} eq "up") {
            $self->{depth} -= $cmd->{distance};
        } else {
            die "should never happen";
        }
        push @{ $self->{done} }, $cmd;
        undef;
    }

    sub do_all_commands() {
        my ($self) = @_;
        while (@{ $self->{commands} }) {
            $self->do_one_command();
        }
        $self->{depth} * $self->{horizontal};
    }

    sub do_one_command_p2() {
        my ($self) = @_;
        my $cmd = shift @{ $self->{commands} };
        if ($cmd->{cmd} eq "forward") {
            $self->{horizontal} += $cmd->{distance};
            $self->{depth} += $self->{aim} * $cmd->{distance};
        } elsif ($cmd->{cmd} eq "down") {
            $self->{aim} += $cmd->{distance};
        } elsif ($cmd->{cmd} eq "up") {
            $self->{aim} -= $cmd->{distance};
        } else {
            die "should never happen";
        }
        push @{ $self->{done} }, $cmd;
        undef;
    }

    sub do_all_commands_p2() {
        my ($self) = @_;
        while (@{ $self->{commands} }) {
            $self->do_one_command_p2();
        }
        $self->{depth} * $self->{horizontal};
    }


}

my $tinput_text = <<'EOF';
forward 5
down 5
forward 8
up 3
down 8
forward 2
EOF

my $tinput = Input->parse($tinput_text);
say Dumper($tinput);
say $tinput->do_all_commands();
$tinput = Input->parse($tinput_text);
say $tinput->do_all_commands_p2();
my $input = Input->parse(read_text("day02.input"));
say $input->do_all_commands();
$input = Input->parse(read_text("day02.input"));
say $input->do_all_commands_p2();

