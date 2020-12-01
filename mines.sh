#!/bin/bash
# mines.sh - the minesweeper kata in Bash
#
# Usage:
#    ./mines.sh grid

# Helper Functions
##################

## plus($1, $2) - adds the lines together, 0-padding the result
## e.g. `plus "010" "011" -> "021"
plus() {
    FORMAT="%0${WIDTH}d\n"
    LINE=$(expr $1 + $2)
    printf $FORMAT $LINE
}

## template($1, $2) - given a pattern of 0/1, keep the input string, or insert a mine "*"
## e.g. (template "123" "010" -> "1*3")
template() {
    perl - $1 $2 <<'PERL'
        my ($input, $pattern) = @ARGV;

        my $offset = 0;
        for my $group ($pattern =~ /(0+|1+)/g) {
            my $len = length $group;
            if ($group =~ /1/) {
                print '*' x $len;
            } else {
                print substr($input, $offset, $len)
            };
            $offset += $len;
        };
PERL
    echo;
}

## zip($FILENAME, $COMMAND) - processes each line of $FILENAME and STDIN in parallel with $COMMAND
zip() {
    FILENAME=$1
    COMMAND=$2
    FD=6
    eval "exec $FD< $1"

    while IFS= read -r line1
    do
        IFS= read -r -u$FD line2
        $COMMAND $line1 $line2
    done
}

## add($FILENAME) - adds the numeric grid in STDIN with the one in $FILENAME, matrix-wise
add() {
    FILENAME=$1
    zip $FILENAME plus
}

## reinsert($FILENAME) - takes the numeric grid in STDIN, and 
##                       reinserts mines based on the binary grid in $FILENAME
reinsert() {
    FILENAME=$1
    zip $FILENAME template
}

## to_binary() - parses a grid with "." for space and "*" for mine, into a numeric grid of 0 and 1.
to_binary() {
    tr ".*" "01"
}

## up(), down(), left(), right() - shift the grid in STDIN in the correct direction,
##                                 padding with 0s on the other side
up()    { (tail +2; echo $ZEROS); }
down()  { echo $ZEROS; cat; }
left()  { sed 's/^.\(.*\)/\10/'; }
right() { sed 's/^\(.*\).$/0\1/'; }

# Main script
#############

FILENAME=$1                      # the input grid...
GRID=$FILENAME.b                 # ... turned into numeric with 0 (space) and 1 (mine)
to_binary < $FILENAME > $GRID

IFS= read sample < $FILENAME
WIDTH=${#sample}                 # global var for width of lines
ZEROS=$(printf "%0${WIDTH}d" 0)  # e.g. for width 5, "00000"

## Generate shifted grids in all 8 directions
up    < $GRID                > $FILENAME.n
down  < $GRID                > $FILENAME.s
left  < $FILENAME.n          > $FILENAME.nw
left  < $FILENAME.b          > $FILENAME.w
left  < $FILENAME.s          > $FILENAME.sw
right < $FILENAME.n          > $FILENAME.ne
right < $FILENAME.b          > $FILENAME.e
right < $FILENAME.s          > $FILENAME.se

## Add all the grids together...
cat       $FILENAME.n \
    | add $FILENAME.s \
    | add $FILENAME.e \
    | add $FILENAME.w \
    | add $FILENAME.nw \
    | add $FILENAME.ne \
    | add $FILENAME.sw \
    | add $FILENAME.se \
    | reinsert $FILENAME.b # ... and reinsert the mines!
