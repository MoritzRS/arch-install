#!/bin/bash

# raw percentage
get_value() {
    local MAX=$(cat /sys/class/backlight/*/max_brightness);
    local VALUE=$(cat /sys/class/backlight/*/brightness);
    echo $((VALUE * 100 / MAX));
}

# raw icon
get_icon() {
    local VALUE=$(($(get_value) - 1));

    if (( $VALUE > 70 )); then echo "";
    elif (( $VALUE > 30 )); then echo "";
    else echo "";
    fi;
}

# brightness listener
value() {
    get_value;
    while true; do
        inotifywait /sys/class/backlight/*/brightness 2> /dev/null | while read line; do
            get_value;
        done;
    done;
}

# icon listener
icon() {
    get_icon;
    while true; do
        inotifywait /sys/class/backlight/*/brightness 2> /dev/null | while read line; do
            get_icon;
        done;
    done;
}

# set value
set() {
    local MAX=$(cat /sys/class/backlight/*/max_brightness);
    light -S $1;
}



if [[ "$1" == "--value" ]]; then value;
elif [[ "$1" == "--icon" ]]; then icon;
elif [[ "$1" == "--set" ]]; then set $2;
fi;