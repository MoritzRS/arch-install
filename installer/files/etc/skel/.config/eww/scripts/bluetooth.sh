#!/bin/bash


# status
status() {
    if [[ "$(bluetoothctl show | grep 'Powered: yes')" != "" ]]; then echo "enabled";
    else echo "disabled";
    fi;
}

# icon
icon() {
    if [[ $(status) == "disabled" ]]; then echo "";
    else echo "";
    fi;
}

# toggle
toggle() {
    if [[ $(status) == "enabled" ]]; then bluetoothctl power off;
    else bluetoothctl power on;
    fi;
}

if [[ "$1" == "--status" ]]; then status;
elif [[ "$1" == "--icon" ]]; then icon;
elif [[ "$1" == "--toggle" ]]; then toggle;
fi;