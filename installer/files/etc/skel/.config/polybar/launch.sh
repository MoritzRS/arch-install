#!/usr/bin/env bash
polybar-msg cmd quit
echo "---" | tee -a /tmp/polybar.log & disown
polybar main 2>&1 | tee -a /tmp/polybar.log & disown