#!/usr/bin/env bash
# "BAT nn%" on battery, "BAT nn% AC" when plugged in, "BAT ?" if pmset
# reports no battery.
line="$(pmset -g batt 2>/dev/null | grep -m1 'InternalBattery')"
pct="$(printf '%s' "$line" | sed -n 's/.*[[:space:]]\([0-9]*\)%.*/\1/p')"
if [ -z "$pct" ]; then
  sketchybar --set "$NAME" label="BAT ?"
elif printf '%s' "$line" | grep -q 'discharging'; then
  sketchybar --set "$NAME" label="BAT ${pct}%"
else
  sketchybar --set "$NAME" label="BAT ${pct}% AC"
fi
