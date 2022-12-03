#!/bin/bash

get_status() {
    if [[ $(rfkill list | grep --line-buffered ': yes') != "" ]]; then echo "enabled";
    else echo "disabled";
    fi;
}


status() {
    get_status;
    rfkill event 2> /dev/null | while read line; do
        get_status;
    done;
}


toggle() {
    rfkill toggle all;
}

if [[ "$1" == "--status" ]]; then status;
elif [[ "$1" == "--toggle" ]]; then toggle;
fi;
