# Waybar

Derived from Fedora's `/etc/xdg/waybar/config.jsonc`, with two changes:

- modules carry text labels (`CPU 12%`, `RAM 43%`) so they read without a
  tooltip — this machine is driven keyboard-only, and waybar tooltips are
  hover-only
- the `sway/*` modules are swapped for their `hyprland/*` equivalents

`fan.sh` prints fan RPM by discovering the hwmon node each run, since hwmon
numbering is not stable across boots. `fanmode.sh` prints the active
`fw-fanctrl` strategy and is refreshed on RTMIN+8 by `hypr/fanctrl-cycle.sh`.

Styling falls back to `/etc/xdg/waybar/style.css`; there is no local one.
