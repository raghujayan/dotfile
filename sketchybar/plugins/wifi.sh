#!/usr/bin/env bash
# "NET <ssid>" on wifi, "NET <ip>" on a wired default route, else "NET off".
# The interface comes from the default route, not a hardcoded en0.
# networksetup -getairportnetwork reports "not associated" on this macOS,
# so the SSID is read from ipconfig instead.
iface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')"
label="NET off"
if [ -n "$iface" ]; then
  ssid="$(ipconfig getsummary "$iface" 2>/dev/null | awk -F' SSID : ' '/ SSID : / {print $2}')"
  if [ -n "$ssid" ]; then
    label="NET $ssid"
  else
    ip="$(ipconfig getifaddr "$iface" 2>/dev/null)"
    [ -n "$ip" ] && label="NET $ip"
  fi
fi
sketchybar --set "$NAME" label="$label"
