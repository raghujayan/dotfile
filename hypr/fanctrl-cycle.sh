#!/usr/bin/env bash
# Cycle to the next fw-fanctrl strategy. The strategy list is read from the
# service, so custom strategies added to its config are picked up too.
set -euo pipefail

next=$(fw-fanctrl --output-format JSON print list | python3 -c '
import json, subprocess, sys
strategies = json.load(sys.stdin)["strategies"]
current = json.loads(
    subprocess.run(["fw-fanctrl", "--output-format", "JSON", "print", "current"],
                   capture_output=True, text=True, check=True).stdout
)["strategy"]
i = strategies.index(current) if current in strategies else -1
print(strategies[(i + 1) % len(strategies)])
')

fw-fanctrl use "$next" >/dev/null
pkill -RTMIN+8 waybar 2>/dev/null || true
