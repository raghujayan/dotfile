#!/usr/bin/env bash
# Focused window title. Empty workspace -> empty label (the command fails).
title="$(aerospace list-windows --focused --format '%{window-title}' 2>/dev/null)"
sketchybar --set "$NAME" label="$title"
