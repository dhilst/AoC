use strict;
use warnings;
use feature 'say';
use File::Slurper qw(read_lines);
use Data::Dumper;

package Input;

sub new {
    my $cls = shift;

    my @ranges;
    my @ids;
    my $state = 'reading_ranges';
    for my $line (@_) {
        $line =~ s/\n+//g; # chomp trailing newlines
        if ($line eq "") {
            $state = 'reading_ids';
            next;
        }
        if ($state eq 'reading_ranges') {
            my ($start, $end) = map int, split /-/, $line;
            push @ranges, [ $start, $end ],
        } elsif ($state eq 'reading_ids') {
            push @ids, int $line;
        }

    }
    return bless {
        ranges => \@ranges,
        ids => \@ids,
    }, $cls;
}

sub each(&$) {
    my ($block, $self) = @_;
    for my $range ($self->{ranges}->@*) {
        for my $id ($self->{ids}->@*) {
            $block->($range, $id);
        }
    }
}

package main;

my @test_input = split /\n/, <<"EOF";
3-5
10-14
16-20
12-18

1
5
8
11
17
32
EOF

my $test_obj = Input->new(@test_input);
# say Dumper($test_obj);

sub play {
    my ($obj) = @_;
    my $count = 0;
    my %visited;
    Input::each sub {
            my ($range, $id) = @_;
            my ($start, $end) = $range->@*;
            if ($id >= $start && $id <= $end) {
                return if exists $visited{$id};
                $visited{$id}++;
                $count++;
                return;
            }
        }, $obj;
    return $count;
}


say "Test solution: ", play($test_obj);

my $input = Input->new(read_lines("day05.input"));

say "Solution: ", play($input);
