#!/bin/bash

# essid
get_essid() {
    nmcli -t -f name connection show --active;
}

# status
get_status() {
    nmcli radio wifi;
}

# icon
get_icon() {
    if [[ $(get_status) == "disabled" ]]; then echo "睊";
    elif [[ $(get_essid) != "" ]]; then echo "直";
    else echo "";
    fi;
}

# essid listener
essid() {
    get_essid;
    nmcli monitor 2> /dev/null | while read line; do
        get_essid;
    done;
}

# status listener
status() {
    get_status;
    nmcli monitor 2> /dev/null | while read line; do
        get_status;
    done;
}

# icon listener
icon() {
    get_icon;
    nmcli monitor 2> /dev/null | while read line; do
        get_icon;
    done;
}

# toggle
toggle() {
    if [[ $(get_status) == "enabled" ]]; then nmcli radio wifi off;
    else nmcli radio wifi on;
    fi;
}

if [[ "$1" == "--essid" ]]; then essid;
elif [[ "$1" == "--status" ]]; then status;
elif [[ "$1" == "--icon" ]]; then icon;
elif [[ "$1" == "--toggle" ]]; then toggle;
fi;