use v5.36;

use Carp;
use Test::More;
use Data::Dumper;
use File::Slurper qw(read_text);

sub aref { \@_ }

my $tinput = <<'EOF';
    [D]    
[N] [C]    
[Z] [M] [P]
 1   2   3 

move 1 from 2 to 1
move 3 from 1 to 3
move 2 from 2 to 1
move 1 from 1 to 2
EOF

sub ::rev_values_ord_by_key($hashref) {
    map { aref reverse $hashref->{$_}->@* }
    sort { $a <=> $b } (keys $hashref->%*);
}

sub ord_values($hashref) {
    map { $hashref->{$_} }
    sort { $a <=> $b } (keys $hashref->%*);
}

package Input {
    sub new ($cls, $tinput) {
        my %boxes_by_position;
        my @stack_ids;
        my @rules;
        for (split /\n/, $tinput) {
            next unless $_;

            while (/\[(\w)\]/g) {
                my $pos = pos($_) - length($&);
                push $boxes_by_position{$pos}->@*, $1;
            }

            if (/move (\d+) from (\d+) to (\d+)/)  {
                push @rules, { move => $1, from => $2,to =>  $3};
                next
            }

            if (/^\s+ (\d+\s*)* \s+$/x) {
                push @stack_ids, int($&) while /\d+/g;
            }
        }

        my @stacks = ::rev_values_ord_by_key(\%boxes_by_position);
        my %stacks;
        $stacks{$_ + 1} = $stacks[$_] for (0 .. $#stacks);

        bless {
            stacks => \%stacks,
            rules => \@rules,
            done => [],
        }, $cls;
    }

    sub do_task($self, $task) {
        ::confess unless
            exists $task->{move};

        my $count = $task->{move};
        my $src = $task->{from};
        my $dst = $task->{to};
        my $stacks = $self->{stacks};
        while ($count-- >= 1) {
            push $stacks->{$dst}->@*, pop $stacks->{$src}->@*;
        }
    }

    sub do_task_9001($self, $task) {
        ::confess unless
            exists $task->{move};

        say "Doing ", ::Dumper $task;

        my $count = $task->{move};
        my $src = $task->{from};
        my $dst = $task->{to};
        my $stacks = $self->{stacks};

        my @out;
        while ($count-- >= 1) {
            unshift @out, pop $stacks->{$src}->@*;
        }
        push $stacks->{$dst}->@*, @out;
    }

    sub do_one_task($self) {
        my $task = $self->{rules}->[0];
        do_task($self, $task);
        push $self->{done}->@*, shift $self->{rules}->@*;
    }

    sub do_all_tasks($self) {
        $self->do_one_task while $self->{rules}->@*;
    }

    sub do_one_task_9001($self) {
        my $task = $self->{rules}->[0];
        do_task_9001($self, $task);
        push $self->{done}->@*, shift $self->{rules}->@*;
    }

    sub do_all_tasks_9001($self) {
        $self->do_one_task_9001 while $self->{rules}->@*;
    }


    sub tops($self) {
        join "", map { $_->[-1] } ::ord_values($self->{stacks});
    }

    sub solve($self) {
        $self->do_all_tasks();
        $self->tops();

    }

    sub solve_p2($self) {
        $self->do_all_tasks_9001();
        $self->tops();
    }
}

$tinput = Input->new($tinput);
$tinput->do_one_task_9001();
say $tinput->solve_p2();
say Dumper $tinput;
my $input= Input->new(read_text("day05.input"));
say $input->solve();
$input= Input->new(read_text("day05.input"));
say $input->solve_p2();
    

