#!/usr/bin/env bash
# CPU busy percent = 100 - idle, from the second top sample (the first one
# reports the since-boot average).
idle="$(top -l 2 -n 0 -s 1 | awk '/CPU usage/ {v=$7} END {sub("%","",v); print v}')"
if [ -n "$idle" ]; then
  busy="$(awk -v i="$idle" 'BEGIN {printf "%d", 100 - i}')"
  sketchybar --set "$NAME" label="CPU ${busy}%"
else
  sketchybar --set "$NAME" label="CPU ?"
fi
