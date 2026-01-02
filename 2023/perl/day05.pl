use v5.36;

use Data::Dumper;
use Test::More;
use List::Util;
use File::Slurper qw(read_text);
use Parallel::ForkManager;

sub ::aref { \@_ };

my $tinput = <<"EOF";
seeds: 79 14 55 13

seed-to-soil map:
50 98 2
52 50 48

soil-to-fertilizer map:
0 15 37
37 52 2
39 0 15

fertilizer-to-water map:
49 53 8
0 11 42
42 0 7
57 7 4

water-to-light map:
88 18 7
18 25 70

light-to-temperature map:
45 77 23
81 45 19
68 64 13

temperature-to-humidity map:
0 69 1
1 0 69

humidity-to-location map:
60 56 37
56 93 4
EOF

package Range {
    use overload
        '""' => sub ($self, @ignored) {
            "$self->{dst_start} $self->{src_start} $self->{len}"
        };

    sub new($cls, $dst_start, $src_start, $len) {
        bless {
            src_start => $src_start, 
            dst_start => $dst_start,
            len => $len,
        }, $cls;
    }

    sub map($self, $src) {
        return undef unless $self->{src_start} <= $src && $src < $self->{src_start} + $self->{len};
        $src + ($self->{dst_start} - $self->{src_start});
    }
}

# A set of Range
package Ranges {
    use overload
        '@{}' => sub($self, @ignored) { $self->{ranges} };

    sub new($cls, @ranges_triples) {
        my @ranges = map { Range->new($_->@*) } @ranges_triples;
        bless {
            ranges => \@ranges
        }, $cls;
    }

    sub from_text($cls, $lines) {
        Ranges->new(map [ split / /, $_ ], split /\n/, $lines);
    }

    sub map($self, $src) {
        my $value =  List::Util::first { defined }
        map { $_->map($src) }
        $self->{ranges}->@*;
        $value // $src;
    }
}

is(Range->new(0, 0, 2)->map(0), 0);
is(Range->new(0, 0, 2)->map(1), 1);
# is(Range->new(0, 10, 2)->map(0), 10);
# is(Range->new(50, 98, 2)->map(50), 98);
# is(Range->new(50, 98, 2)->map(51), 99);
# is(Range->new(50, 98, 2)->map(52), undef);
my $seed_to_soil_map = Ranges->from_text(<<"EOF");
50 98 2
52 50 48
EOF

# is($seed_to_soil_map->map(50), 98);
# is($seed_to_soil_map->map(51), 99);
# is($seed_to_soil_map->map(52), 50);
# is($seed_to_soil_map->map(49), 49);
# is($seed_to_soil_map->map(79), 81);


package Input {
    sub parse($cls, $text) {
        my %out;
        my $section;
        for (split /\n/, $text) {
            next unless $_;
            if (/seeds: (.*$)/) {
                $out{seeds} = [ map int, split / /, $1 ];
            } elsif (/^([^ ]+) map:/) {
                $section = $1;
                push $out{order}->@*, $section;
            } elsif (/(\d+( \d+)*)/) {
                push $out{$section}->@*, [ map int, split / /, $_ ];
            } else {
                die "invalid line $_";
            }
        }
        for ($out{order}->@*) {
            $out{$_} = Ranges->new($out{$_}->@*);
        }
        bless \%out, $cls;
    }

    sub unparse($self) {
        my $buf = "seeds: ";
        $buf .= join " ",  $self->{seeds}->@*;
        $buf .= "\n\n";
        for my $key ($self->{order}->@*) {
            my $value = $self->{$key};
            $buf .= "$key map:\n";
            $buf .= join "\n", $value->@*;
            $buf .= "\n\n";
        }
        $buf =~ s/\n+$/\n/;
        $buf;
    }

    sub map_seed($self, $seed) {
        my $value = $seed;
        for ($self->{order}->@*) {
            my $newvalue = $self->{$_}->map($value);
            # say sprintf "% 30s map : $value => $newvalue", $_;
            $value = $newvalue;
        }
        $value;
    }

    sub map_seeds($self) {
        map { $self->map_seed($_) } $self->{seeds}->@*;
    }

    sub map_seeds_pt2($self) {
        my $pm = Parallel::ForkManager->new(`nproc --all`);
        my $min = 9999999999;
        $pm->run_on_finish(sub(
                $pid, $exit, $ident,
                $signal, $core, $data) {
                my $local_min = $data->[0];
                say "finishing $ident local_min = $local_min";
                $min = $local_min < $min ? $local_min : $min;
            });
        for my $pair (List::Util::pairs $self->{seeds}->@*) {
            my ($start, $len) = $pair->@*;
            $pm->start("$start:$len") and next;
            say "starting $start:$len";
            my $min;
            for my $seed ($start .. $start + $len - 1) {
                my $value = $self->map_seed($seed);
                $min = $value if !defined $min || $value < $min;
            }
            $pm->finish(0, [ $min ]);
        }
        $pm->wait_all_children();
        $min;
    }

    sub solve($self) {
        List::Util::min($self->map_seeds());
    }

    $Data::Dumper::Indent = 2;
    ::is_deeply(::aref(split /\n/, Input->parse($tinput)->unparse()), ::aref(split /\n/, $tinput));
    my $tmapper = Input->parse($tinput);
    say $tmapper->map_seeds_pt2();
    # say ::Dumper $tmapper->solve();
    my $mapper = Input->parse(::read_text("day05.input"));
    # say ::Dumper $mapper->solve();
    say $mapper->map_seeds_pt2();
}

done_testing;
