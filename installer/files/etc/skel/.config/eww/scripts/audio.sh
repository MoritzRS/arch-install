#!/bin/bash

# raw volume
get_volume() {
    pamixer --get-volume;
}

# raw muted state
get_muted() {
    pamixer --get-mute;
}

# raw icon
get_icon() {
    local VOLUME=$(get_volume);
    if [[ $(get_muted) == "true" ]]; then echo "ﱝ";
    elif (( $VOLUME > 80)); then echo "";
    elif (( $VOLUME > 60)); then echo "墳";
    elif (( $VOLUME > 40)); then echo "";
    else echo "";
    fi;
    
}

# volume listener
volume() {
    get_volume;
    pactl subscribe | grep --line-buffered "'change' on sink" | while read line; do
        get_volume;
    done;
}

# muted listener
muted() {
    get_muted;
    pactl subscribe | grep --line-buffered "'change' on sink" | while read line; do
        get_muted;
    done;
}

# icon listener
icon() {
    get_icon;
    pactl subscribe | grep --line-buffered "'change' on sink" | while read line; do
        get_icon;
    done;
}

# toggle muted state
toggle() {
    pamixer --toggle-mute;
}

# set volume
set() {
    pamixer --set-volume $1;
}

if [[ "$1" == "--volume" ]]; then volume;
elif [[ "$1" == "--muted" ]]; then muted;
elif [[ "$1" == "--icon" ]]; then icon;
elif [[ "$1" == "--toggle" ]]; then toggle;
elif [[ "$1" == "--set" ]]; then set $2;
fi;