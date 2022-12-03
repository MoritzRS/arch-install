#!/bin/bash

# raw status
get_status() {
    cat /sys/class/power_supply/BAT*/status;
}

# raw capcity
get_capacity() {
    cat /sys/class/power_supply/BAT*/capacity;
}

# raw icon
get_icon() {
    local CAPACITY=$(($(get_capacity) - 1));
    local ICON="";
    if [[ "$(get_status)" == "Charging" ]]; then ICON+=""
    fi;

    if (( $CAPACITY > 95 )); then ICON+="";
    elif (( $CAPACITY > 85 )); then ICON+="";
    elif (( $CAPACITY > 75 )); then ICON+="";
    elif (( $CAPACITY > 65 )); then ICON+="";
    elif (( $CAPACITY > 55 )); then ICON+="";
    elif (( $CAPACITY > 45 )); then ICON+="";
    elif (( $CAPACITY > 35 )); then ICON+="";
    elif (( $CAPACITY > 25 )); then ICON+="";
    elif (( $CAPACITY > 15 )); then ICON+="";
    else ICON+="";
    fi;

    echo $ICON;
}

# status listener
status() {
    get_status;
    while true; do
        inotifywait /sys/class/power_supply/BAT*/status 2> /dev/null | while read line; do
            get_status;
        done;
    done;
}

# capacity listener
capacity() {
    get_capacity;
    while true; do
        inotifywait /sys/class/power_supply/BAT*/capacity 2> /dev/null | while read line; do
            get_capacity;
        done;
    done;
}

# icon listener
icon() {
    get_icon;
    while true; do
        inotifywait /sys/class/power_supply/BAT*/status /sys/class/power_supply/BAT*/capacity 2> /dev/null | while read line; do
            get_icon;
        done;
    done;
}

if [[ "$1" == "--status" ]]; then status;
elif [[ "$1" == "--capacity" ]]; then capacity;
elif [[ "$1" == "--icon" ]]; then icon;
fi;