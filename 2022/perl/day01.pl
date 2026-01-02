use v5.36;

use Data::Dumper;
use File::Slurper qw(read_text);
use List::Util;


sub parse($lines) {
    my @out;
    my @inner;
    for (split /\n/, $lines) {
        if (!$_) {
            push @out, [ @inner ];;
            @inner = (),
            next;
        }
        push @inner, $_;
    }
    push @out, [ @inner ];
    @out;
}

sub solve(@parsed) {
    List::Util::max map { List::Util::sum $_->@* } @parsed;
}

sub solve_p2(@parsed) {
    List::Util::sum List::Util::head 3, sort { $b <=> $a } map { List::Util::sum $_->@* } @parsed;
}


my $tinput= <<"EOF";
1000
2000
3000

4000

5000
6000

7000
8000
9000

10000
EOF

sub aref { \@_ }


# say Dumper solve parse $tinput;
# say Dumper solve parse read_text("day01.input");
say Dumper solve_p2 parse $tinput;
say Dumper solve_p2 parse read_text("day01.input");
