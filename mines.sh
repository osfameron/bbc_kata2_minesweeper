#!/bin/bash

plus() {
    FORMAT="%0${WIDTH}d\n"
    LINE=$(expr $line1 + $line2)
    printf $FORMAT $LINE
}

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

add() {
    FILENAME=$1
    zip $FILENAME plus
}

reinsert() {
    FILENAME=$1
    zip $FILENAME template
}

to_binary() {
    tr ".*" "01"
}

FILENAME=$1
GRID=$FILENAME.b
to_binary < $FILENAME > $GRID

IFS= read sample < $FILENAME
WIDTH=${#sample}
ZEROS=$(printf "%0${WIDTH}d" 0)

left() {
    sed 's/^.\(.*\)/\10/'
}

right() {
    sed 's/^\(.*\).$/0\1/'
}

(tail +2 $GRID; echo $ZEROS) > $FILENAME.n
(echo $ZEROS; cat $GRID)     > $FILENAME.s
left  < $FILENAME.n          > $FILENAME.nw
left  < $FILENAME.b          > $FILENAME.w
left  < $FILENAME.s          > $FILENAME.sw
right < $FILENAME.n          > $FILENAME.ne
right < $FILENAME.b          > $FILENAME.e
right < $FILENAME.s          > $FILENAME.se

cat       $FILENAME.n \
    | add $FILENAME.s \
    | add $FILENAME.e \
    | add $FILENAME.w \
    | add $FILENAME.nw \
    | add $FILENAME.ne \
    | add $FILENAME.sw \
    | add $FILENAME.se \
    | reinsert $FILENAME.b
