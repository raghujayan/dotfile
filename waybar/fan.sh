#!/usr/bin/env bash
# Print fan RPM from the first hwmon device exposing a fan*_input.
# Device numbering is not stable across boots, so discover it each run.
set -u
for f in /sys/class/hwmon/hwmon*/fan*_input; do
    [ -r "$f" ] || continue
    rpm=$(cat "$f" 2>/dev/null) || continue
    [ -n "$rpm" ] || continue
    printf 'FAN %s rpm\n' "$rpm"
    exit 0
done
printf 'FAN n/a\n'
