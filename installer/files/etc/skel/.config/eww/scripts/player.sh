#!/bin/bash

play() {
	playerctl play;
}

pause() {
	playerctl pause;
}

previous() {
	playerctl previous;
}

next() {
	playerctl next;
}

status() {
	playerctl --follow status;
}

title() {
	playerctl --follow metadata title;
}

if [[ "$1" == "--play" ]]; then play;
elif [[ "$1" == "--pause" ]]; then pause;
elif [[ "$1" == "--previous" ]]; then previous;
elif [[ "$1" == "--next" ]]; then next;
elif [[ "$1" == "--status" ]]; then status;
elif [[ "$1" == "--title" ]]; then title
fi;