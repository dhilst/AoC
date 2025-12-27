use v5.36;
use builtin qw(true false);

use Carp;
use Data::Dumper;
use Test::More;
use File::Slurper qw(read_lines read_text);
use Type::Params qw(signature);
use Types::Standard qw(:all); 

sub aref { \@_ };
sub dref { $_[0]->@* };


package Utils::Methods {
    sub call($method, $args, $obj) {
        return $obj->$method($args->@*);
    }
}

package Utils::Ints {
    sub between($a, $b, $c) {
        return $a <= $b && $b <= $c;
    }
}

package Utils::Arrays {
    use Carp;
    use Type::Params qw(signature);
    use Types::Standard qw(:all); 

    sub is_in {
        state $sig = signature(positional =>
            [Any, ArrayRef[Any]]);
        my ($needle, $haystack) = $sig->(@_);
        grep { $needle eq $_ } $haystack->@*;
    }

    sub index_of {
        state $sig = signature(positional =>
            [Any, ArrayRef[Any]]);
        my ($needle, $haystack) = $sig->(@_);
        my $index = 0;
        for ($haystack->@*) {
            if ($needle eq $_) {
                return $index;
            }
            $index++;
        }
        undef;
    }

    sub swap {
        state $sig = signature(positional =>
            [Int, Int, ArrayRef[Any]]);

        my ($pos1, $pos2, $array) = $sig->(@_);

        confess "invalid index" unless 
            Utils::Ints::between(0, $pos1, $#$array) &&
            Utils::Ints::between(0, $pos2, $#$array);
            
        ($array->[$pos2], $array->[$pos1]) = ($array->[$pos1], $array->[$pos2])
    }

    sub get {
        state $sig = signature(positional =>
            [Int, ArrayRef[Any]]);
        my ($pos1, $array) = $sig->(@_);
        return $array->[$pos1];
    }

    sub get_middle {
        state $sig = signature(positional =>
            [ArrayRef[Any]]);
        my ($array) = $sig->(@_);
        return $array->[$#$array / 2];
    }
}

package Rule {
    use Type::Params qw(signature);
    use Types::Standard qw(:all); 
    use overload
        '""' => \&to_str,
        '@{}' => \&to_array_ref,
        ;

    sub from_str {
        state $sig = signature(positional => [ClassName, Str]);

        my ($cls, $str) = $sig->(@_);
        my ($before, $after) = map int, split /\|/, $str;
        return bless {
            before => $before,
            after => $after,
        }, $cls;

    }

    sub to_str {
        state $sig = signature(positional => [
            InstanceOf['Rule'], Optional[Any], Optional[Any],
        ]); 
        my ($self) = $sig->(@_);
        "$self->{before}|$self->{after}";
    }

    sub to_array_ref {
        my ($self) = @_;
        return [$self->{before}, $self->{after}];
    }

    sub check {
        state $sig = signature(positional =>
            [InstanceOf['Rule'], InstanceOf['Update']]);

        my ($self, $update) = $sig->(@_);
        my @data = grep { Utils::Arrays::is_in($_, $self->to_array_ref) } $update->@*;
        my ($before, $after) = $self->@*;
        my $before_idx = Utils::Arrays::index_of($before, $update->to_array_ref);
        my $after_idx = Utils::Arrays::index_of($after, $update->to_array_ref);
        return 1 if grep { !defined } $before_idx, $after_idx;
        return $before_idx < $after_idx;
    }
}

package Failure {
    use Type::Params qw(signature);
    use Types::Standard qw(:all); 

    use overload
        '""' => \&to_str;
    sub new {
        state $sig = signature(positional =>
            [ClassName, InstanceOf['Update'], InstanceOf['Rule'], InstanceOf['Rules']]);
        my ($cls, $update, $rule, $rules) = $sig->(@_);
        return bless {
            update => $update,
            rule => $rule,
            rules => $rules,
        }
    }

    sub to_str {
        my ($self) = @_;
        sprintf "%s fails against %s",
            $self->{update},
            $self->{rule};
    }

    sub swap {
        my ($self) = @_;
        say "calling Failure swap $self";
        my ($before, $after) = $self->{rule}->@*;
        my $update = $self->{update};
        $update->apply_inplace($self->{rule});
        my $retries = 100;
        while ((my $failure = $self->{rules}->invalid($update)) && $retries-- > 0) {
            $update->apply_inplace($failure->{rule});
        }
        die if $retries < 0;
        return $update;
    }
}


package Update {
    use Type::Params qw(signature);
    use Types::Standard qw(:all); 
    use overload
        '""' => \&to_str,
        '@{}' => \&to_array_ref;

    sub from_str {
        state $sig = signature(positional =>
            [ClassName, Str]);
        my ($cls, $str) = $sig->(@_);
        return bless {
            pages => [ map int, split /,/, $str ],
        }, $cls;
    }

    sub from_array {
        state $sig = signature(positional =>
            [ClassName, ArrayRef[Int]]);
        my ($cls, $array_ref) = $sig->(@_);
        return bless {
            pages => $array_ref,
        }, $cls;
    }

    sub apply_inplace {
        state $sig = signature(positional =>
            [InstanceOf['Update'], InstanceOf['Rule']]);
        my ($self, $rule) = $sig->(@_);
        my ($before, $after) = $rule->@*;
        my $before_idx = Utils::Arrays::index_of($before, $self->to_array_ref);
        my $after_idx = Utils::Arrays::index_of($after, $self->to_array_ref);
        Utils::Arrays::swap($before_idx, $after_idx, $self->to_array_ref);
        undef;
    }

    sub to_str {
        my ($self) = @_;
        join ",", $self->{pages}->@*;
    }

    sub to_array_ref{
        my ($self) = @_;
        return $self->{pages};
    }
}


package Rules {
    use Type::Params qw(signature);
    use Types::Standard qw(:all); 
    use overload
        '""' => \&to_str,
        '@{}' => \&to_array_ref;

    sub from_array {
        state $sig = signature(positional =>
            [ClassName, ArrayRef[InstanceOf['Rule']]]);
        my ($cls, $rules) = $sig->(@_);
        return bless {
            rules => $rules,
        }, $cls;
    }

    sub invalid {
        state $sig = signature(positional =>
            [InstanceOf["Rules"], InstanceOf['Update']]);
        my ($self, $update) = $sig->(@_);

        my @invalid;
        for my $rule ($self->{rules}->@*) {
            if ($rule->check($update) == 0) {
                return Failure->new($update, $rule, $self)
            }
        }
        return undef;
    }

    sub to_array_ref {
        my ($self) = @_;
        return $self->{rules};
    }
}

package Input {
    use Type::Params qw(signature);
    use Types::Standard qw(:all); 
    sub new {
        state $sig = signature(positional =>
            [ClassName, Str]);
        my ($cls, $str) = $sig->(@_);
        my $parsing_state = "reading_rules";
        my (@rules, @updates);
        for my $line (split /\n/, $str) {
            chomp $line;

            if (!$line) {
                $parsing_state = "reading_updates";
                next;
            }

            if ($parsing_state eq "reading_rules") {
                push @rules, Rule->from_str($line);
            } elsif ($parsing_state eq "reading_updates") {
                push @updates, Update->from_str($line);
            }

        }
        return bless {
            rules => Rules->from_array(\@rules),
            updates => \@updates,
        }, $cls;
    }
}

package main;

my $tinput = Input->new(<<"EOF");
47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47
EOF


sub validate_all {
    state $sig = signature(positional => 
        [InstanceOf['Input']]);

    my ($tinput) = $sig->(@_);

    my (@valid, @invalid);
    OUTER: for my $update ($tinput->{updates}->@*) {
        my $failed = 0;
        my $failure = $tinput->{rules}->invalid($update);
        if (defined $failure) {
            push @invalid, $failure;
        } else {
            push @valid, $update;
        }
    }

    return {
        valid => [ List::Util::uniq @valid ], 
        invalid => [ List::Util::uniq @invalid ],
    }
}

sub solve {
    my ($tinput) = @_;
    List::Util::sum map { Utils::Arrays::get_middle Update::to_array_ref($_) } map { Failure::swap($_) } validate_all($tinput)->{invalid}->@*
}

say solve $tinput;

my $input = Input->new(read_text("day05.input"));
say solve  $input;
