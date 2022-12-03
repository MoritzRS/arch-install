#!/bin/bash

# raw status
get_status() {
    # icons
    local EMPTY=""
    local OCCUPIED=""
    local ACTIVE=""

    # data
    local DESKTOPS=$(bspc query -D);
    local DESKTOPS_N=$(echo $DESKTOPS | wc -w);
    local CURRENT=$(bspc query -D -d)
    local WORKSPACES="["
    local i=1;
    for DESKTOP in $DESKTOPS; do
        # set icon and number
        if [[ $CURRENT == $DESKTOP ]]; then WORKSPACES+="[\"${ACTIVE}\", $(($i))]";
        elif [[ $(bspc query -N -d $DESKTOP) != "" ]]; then WORKSPACES+="[\"${OCCUPIED}\", $(($i))]";
        else WORKSPACES+="[\"${EMPTY}\", $(($i))]";
        fi;

        # set trailing comma
        if [[ $i != $DESKTOPS_N ]]; then WORKSPACES+=",";
        fi;

        i=$(($i + 1));
    done;
    WORKSPACES+="]";
    
    echo $WORKSPACES;
}

# status listener
status() {
    get_status;
    bspc subscribe desktop_focus node_add node_remove 2> /dev/null | while read line; do
        get_status;
    done
}

status;