#!/usr/bin/env bash
# Highlight this workspace item when it is the focused one.
# $1 = workspace id; FOCUSED_WORKSPACE comes from the aerospace trigger.
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" background.drawing=on label.color=0xff1e1e2e
else
  sketchybar --set "$NAME" background.drawing=off label.color=0xffcdd6f4
fi
