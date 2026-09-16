#!/usr/bin/env bash
# Print the active fw-fanctrl strategy for waybar.
set -u
out=$(fw-fanctrl --output-format JSON print current 2>/dev/null) || { printf 'MODE n/a\n'; exit 0; }
printf 'MODE %s\n' "$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin)["strategy"])' 2>/dev/null || echo '?')"
