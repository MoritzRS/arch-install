#!/bin/bash

# toggle
toggle() {
    dunstctl set-paused toggle;
}

# raw paused
paused() {
    dunstctl is-paused;
}

# raw icon
icon() {
    if [[ $(paused) == "true" ]]; then echo "";
    else echo "";
    fi;
}

# raw count
count() {
    local WAITING=$(dunstctl count waiting);
    local DISPLAYED=$(dunstctl count displayed);
    local HISTORY=$(dunstctl count history);
    echo $(($WAITING + $DISPLAYED + $HISTORY));
}


if [[ "$1" == "--toggle" ]]; then toggle;
elif [[ "$1" == "--paused" ]]; then paused;
elif [[ "$1" == "--count" ]]; then count;
elif [[ "$1" == "--icon" ]]; then icon;
fi;