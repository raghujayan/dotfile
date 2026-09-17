#!/usr/bin/env bash
# Output volume as "VOL nn%", or "VOL mute". Runs on the volume_change
# event and once at startup; osascript is asked each time for the mute flag.
settings="$(osascript -e 'get volume settings' 2>/dev/null)"
vol="$(printf '%s' "$settings" | sed -n 's/.*output volume:\([0-9]*\).*/\1/p')"
muted="$(printf '%s' "$settings" | sed -n 's/.*output muted:\([a-z]*\).*/\1/p')"
if [ -z "$vol" ]; then
  sketchybar --set "$NAME" label="VOL ?"
elif [ "$muted" = "true" ]; then
  sketchybar --set "$NAME" label="VOL mute"
else
  sketchybar --set "$NAME" label="VOL ${vol}%"
fi
