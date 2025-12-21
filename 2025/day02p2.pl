#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use Data::Dumper qw(Dumper);
use Scalar::Util qw(looks_like_number);
use List::Util qw(sum);
use Test::More;
use Carp qw(croak);
use Benchmark qw(cmpthese timeit timethis timethese);
use Parallel::ForkManager;


sub parse_range {
    my ($start, $end) = split /-/, $_[0], 2;
    croak "Invalid range $_[0]"
        unless looks_like_number($start) 
            && looks_like_number($end);
    return ($start..$end);
}

sub parse_line {
    return [ map { parse_range $_ } split(/,/, $_[0]) ];
}

# 
sub chunks {
    my ($strinput, $step) = @_;
    die "Expect step to be > 0, found $step"
        unless $step > 0;

    my $len = length($strinput);
    my $max = $len - $step;
    my @out;
    my $i = 0;
    for (; $i <= $max; $i += $step) {
        push @out, substr($strinput, $i, $step)
    }
    push @out, substr($strinput, $i)
        if $i < $len;
    return \@out;
}

# returns 1 if all strings in $_[0] have the same length
sub all_same_length {
    my ($arrayp) = @_;
    my %tracker;

    for ($arrayp->@*) {
        $tracker{length($_)}++;
    }

    return keys %tracker == 1;
}

sub composed_by_substr {
    my ($input, $chunk) = @_;
    my $ilen = length($input);
    my $clen = length($chunk);

    return 0 if $ilen % $clen != 0;

    for (my $i = 0; $i < $ilen; $i += $clen) {
        return 0 unless substr($input, $i, $clen) eq $chunk;
    }
    return 1;
}

sub composed_by_unpack {
    my ($input, $chunk) = @_;
    my $ilen = length($input);
    my $clen = length($chunk);

    return 0 if $ilen % $clen != 0;

    for (my $i = 0; $i < $ilen; $i += $clen) {
        return 0
            unless unpack("x$i a$clen", $input) eq $chunk;
    }
    return 1;
}

sub composed_by_vec {
    my ($input, $chunk) = @_;
    my $ilen = length($input);
    my $clen = length($chunk);

    return 0 if $ilen % $clen != 0;

    for (my $i = 0; $i < $ilen; $i++) {
        return 0
            if vec($input, $i, 8) != vec($chunk, $i % $clen, 8);
    }
    return 1;
}

sub composed_by_regex {
    my ($input, $chunk) = @_;
    my $clen = length($chunk);

    return 0 if length($input) % $clen != 0;
    return $input =~ /^(?:\Q$chunk\E)+$/;
}

sub composed_by_regex_v2 {
    my ($input, $chunk) = @_;
    my $ilen = length($input);
    my $clen = length($chunk);

    return 0 if length($input) % $clen != 0;

    my $reg = qr/\G\Q$chunk\E/;
    pos($input) = 0;
    while (pos($input) < $ilen) {
        return 0 unless ($input =~ /$reg/gc);
    }
    return 1;
}

sub composed_by_chunk {
    my ($input, $chunk) = @_;

}

sub composed_by {
    return &composed_by_substr;
}


sub invalid {
    my ($input, $d) = @_;
    my $len = length($input);
    my $chunksp = chunks $input, $len / $d;
    return 0 unless all_same_length $chunksp;

    for my $chunk ($chunksp->@*) {
        return 1 if composed_by($input, $chunk);
    }

    return 0;
}

sub chunk_array {
    my $n = shifu   t;
    my $arrayref = shift;
    my $chunksiz = $arrayref->@* / $n;
    my @out;
    push @out,[ splice $arrayref->@*, 0, $chunksiz ] while $arrayref->@*; 
    return \@out;
}


sub collect_invalids {
    my ($line) = @_;
    my $input = parse_line $line;

    my %out;
    for my $id ($input->@*) {
        next if $out{$id};

        my $id_len = length($id);
        for (my $i = 2; $id_len / $i >= 1; $i++) {
            next if $out{$id};
            $out{$id} = 1
                if !$out{$id} && invalid($id, $i);
        }
    }

    return [ keys %out ];
}

sub collect_invalids_parallel {
    my ($line) = @_;
    my $input = parse_line $line;
    my $nproc = int(`nproc --all`);
    my $chunks = chunk_array($nproc, $input);
    my $pm = Parallel::ForkManager->new($nproc);
    my @out;
    $pm->run_on_finish(sub {
            my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $datap) = @_;
            push @out, $datap->@*
                if (defined($datap));
        });

    for my $chunk ($chunks->@*) {
        $pm->start and next;
        my %out;
        for my $id ($chunk->@*) {
            next if $out{$id};

            my $id_len = length($id);
            for (my $i = 2; $id_len / $i >= 1; $i++) {
                $out{$id} = 1
                    if invalid($id, $i);
            }
        }

        $pm->finish(0, [ map { int($_) } keys %out ]);
    }
    $pm->wait_all_children;

    return \@out;
}



my $test_input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";
if ($ARGV[0] eq "test") {
    is_deeply [ parse_range('1-3') ], [ 1,2,3 ];
    is_deeply parse_line('1-3,9-12'), [ 1,2,3,9,10,11,12 ];
    is_deeply chunks("aabbcc", 2), [ "aa", "bb", "cc" ];
    is_deeply all_same_length([ "aa", "bb", "cc" ]), 1;
    is_deeply chunks("123123123", 4), [ "1231", "2312", "3" ];
    is_deeply(
        chunk_array(2, [1,2,3,4]),
        [[1,2],[3,4]]);
    is invalid(10,2), 0;
    is invalid(11, 2), 1;
    is invalid(6464, 2), 1;
    is invalid(6465, 2), 0;
    is invalid(123123123, 3), 1;
    ok composed_by_regex_v2("123123123", "123");
    ok ! composed_by_regex_v2("123123124", "123");
    ok ! composed_by_regex_v2("423123123", "123");
    done_testing;
    exit 0;
}

# 
# say Dumper(collect_invalids_parallel($test_input));
# say Dumper(collect_invalids($test_input));

#    123123123
#   1231   2312 3
#  123  123  123
#  12 31 23 12 3
# 1 2 3 1 2 3 1 2 3


open my $fh, "<", "day02p2.input"
    or die "no day02.input found: $!";

my $prod_input = <$fh>;

close $fh;

say sum(collect_invalids_parallel($prod_input)->@*)
    if $ARGV[0] eq "parallel";

say sum(collect_invalids($prod_input)->@*)
    if $ARGV[0] eq "single";

use Benchmark qw(cmpthese);

my $input = "123123123123123523123123";
my $chunk = "123";

say "Success path";
cmpthese(-5, {
    substr => sub {
        composed_by_substr($input, $chunk);
    },
    unpack => sub {
        composed_by_unpack($input, $chunk);
    },
    vec => sub {
        composed_by_vec($input, $chunk);
    },
    regex => sub {
        composed_by_regex($input, $chunk);
    },
    regex2 => sub {
        composed_by_regex_v2($input, $chunk);
    },
}) if $ARGV[0] eq "cmp";


say "Failing at start";
$input = "523123123123123123523123";

cmpthese(-5, {
    substr => sub {
        composed_by_substr($input, $chunk);
    },
    unpack => sub {
        composed_by_unpack($input, $chunk);
    },
    vec => sub {
        composed_by_vec($input, $chunk);
    },
    regex => sub {
        composed_by_regex($input, $chunk);
    },
    regex2 => sub {
        composed_by_regex_v2($input, $chunk);
    },
}) if $ARGV[0] eq "cmp";

say "Failing at middle ";
$input = "123123123125123123523123";

cmpthese(-5, {
    substr => sub {
        composed_by_substr($input, $chunk);
    },
    unpack => sub {
        composed_by_unpack($input, $chunk);
    },
    vec => sub {
        composed_by_vec($input, $chunk);
    },
    regex => sub {
        composed_by_regex($input, $chunk);
    },
    regex2 => sub {
        composed_by_regex_v2($input, $chunk);
    },
}) if $ARGV[0] eq "cmp";

say "Failing at end";
$input = "123123123123123123523125";


cmpthese(-5, {
    substr => sub {
        composed_by_substr($input, $chunk);
    },
    unpack => sub {
        composed_by_unpack($input, $chunk);
    },
    vec => sub {
        composed_by_vec($input, $chunk);
    },
    regex => sub {
        composed_by_regex($input, $chunk);
    },
    regex2 => sub {
        composed_by_regex_v2($input, $chunk);
    },
}) if $ARGV[0] eq "cmp";
