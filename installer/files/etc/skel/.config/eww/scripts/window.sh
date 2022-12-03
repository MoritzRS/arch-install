#!/bin/bash

# raw name
get_name() {
    xdotool getactivewindow getwindowclassname;
}

# name listener
name() {
    get_name;
    bspc subscribe 2> /dev/null | while read line; do
        get_name;
    done;
}

if [[ "$1" == "--name" ]]; then name;
fi