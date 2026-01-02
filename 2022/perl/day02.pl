use v5.36;

use Data::Dumper;
use File::Slurper qw(read_text);
use List::Util;
use Carp;
use Test::More;

sub decrypt_letters($line_text) {
    local $_ = $line_text;
    s/A/R/;
    s/B/P/;
    s/C/S/;
    s/X/R/;
    s/Y/P/;
    s/Z/S/;
    $_;
}

sub decrypt_letter($letter) {
    state %map = (
        A => "R",
        B => "P",
        C => "S",
        X => "R",
        Y => "P",
        Z => "S"
    );
    $map{$letter} // confess "invalid letter $letter";
}

sub decrypt_letter_p2($letter) {
    state %map = (
        A => "R",
        B => "P",
        C => "S",
        X => "LOSE",
        Y => "DRAW",
        Z => "WIN"
    );
    $map{$letter} // confess "invalid letter $letter";
}

sub parse($lines) {
    map [ split / /, $_ ], map { decrypt_letters $_} split /\n/, $lines;
}

sub parse_p2($lines) {
    map { find_p1_move($_->@*) }
    map [ map { decrypt_letter_p2($_) } split / /, $_ ],
    split /\n/, $lines;
}

sub rock_papper_scissors($move_2, $move_1) {
    if ($move_1 eq "R") {
        if ($move_2 eq "P") {
            return -1;
        } elsif ($move_2 eq "S") {
            return 1;
        } elsif ($move_2 eq "R") {
            return 0;
        } else {
            ::confess "invalid move $move_2";
        }
    } elsif ($move_1 eq "P") {
        if ($move_2 eq "P") {
            return 0;
        } elsif ($move_2 eq "S") {
            return -1;
        } elsif ($move_2 eq "R") {
            return 1;
        } else {
            ::confess "invalid move $move_2";
        }
    } elsif ($move_1 eq "S") {
        if ($move_2 eq "P") {
            return 1;
        } elsif ($move_2 eq "S") {
            return 0;
        } elsif ($move_2 eq "R") {
            return -1;
        } else {
            ::confess "invalid move $move_2";
        }
    } else {
        ::confess "invalid move $move_1";
    }
}

sub find_p1_move($player_2_move, $goal) {
    state %map = (
        LOSE => -1,
        DRAW => 0,
        WIN => 1,
    );
    my $goal_score = $map{$goal} // ::confess "invalid goal $goal";
    my $move = List::Util::first { $goal_score == rock_papper_scissors($player_2_move, $_); } "R", "P", "S";
    die "invalid move returned $move, (p2 move: $player_2_move" unless $move =~ /[RPS]/;
    [$player_2_move, $move];
}

sub result_score($result) {
    state %map = (
        -1 => 0,
        0 => 3,
        1 => 6,
    );
    $map{$result} // ::confess "invalid result value $result";
}

sub move_score($move) {
    state %map = (
        R => 1,
        P => 2,
        S => 3,
    );
    $map{$move} // ::confess "invalid move $move";
}

sub game_score($result, $move) {
    result_score($result) + move_score($move);
}

sub translate_moves($text) {
    local $_ = $text;
    s/R/PEDRA/g and return $_;
    s/P/PAPEL/g and return $_;
    s/S/TESOURA/g and return $_;
    confess "Invalid moves $text";
}

sub translate_result($result) {
    if ($result == 0) {
        return "DRAW";
    } elsif ($result == -1) {
        return "LOSE";
    } elsif ($result == 1) {
        return "WIN ";
    } else {
        confess "invalid resultt $result";
    }
}

sub game_play($move_2, $move_1) {
    my $result = rock_papper_scissors($move_2, $move_1);
    my $score = game_score($result, $move_1);
    my $result_score = result_score($result);
    my $move_score = move_score($move_1);
    my $move_1t = translate_moves($move_1);
    my $move_2t = translate_moves($move_2);
    say sprintf "%-10s %-10s = %-04s (score: %2d + %2d = %2d)",
        $move_1t, $move_2t, translate_result($result), 
        $move_score, $result_score, $score;
    $score;
}

sub games_play(@games) {
    map { game_play($_->@*) } @games;
}

my $tinput = <<'EOF';
A Y
B X
C Z
EOF

sub aref { \@_ }
# say List::Util::sum games_play parse $tinput;
say 
    List::Util::sum
    games_play
    parse_p2 $tinput;

say 
    List::Util::sum
    games_play
    parse_p2 read_text "day02.input";;
# say List::Util::sum games_play parse read_text "day02.input";
