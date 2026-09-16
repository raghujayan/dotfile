#!/usr/bin/env bash
# Close every window on the focused workspace.
#
# Uses closewindow, the same polite request a title-bar close button sends,
# so apps still get to prompt about unsaved work.
set -euo pipefail

hyprctl clients -j | python3 -c '
import json, sys, subprocess

clients = json.load(sys.stdin)
active = json.loads(
    subprocess.run(["hyprctl", "activeworkspace", "-j"],
                   capture_output=True, text=True, check=True).stdout
)["id"]

targets = [c["address"] for c in clients if c["workspace"]["id"] == active]
for address in targets:
    subprocess.run(["hyprctl", "dispatch", "closewindow", f"address:{address}"],
                   capture_output=True, check=False)
print(f"closed {len(targets)} window(s) on workspace {active}")
'
