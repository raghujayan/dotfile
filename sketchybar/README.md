# SketchyBar

Top bar for the Mac, mirroring the waybar modules on the Fedora machine:
workspaces, CPU, RAM, and the menu-bar items. Text labels only, no nerd font,
for the same keyboard-only reason as `waybar/README.md`.

## Install

```sh
brew tap FelixKratz/formulae
brew trust --formula felixkratz/formulae/sketchybar
brew install sketchybar
ln -s "$PWD" ~/.config/sketchybar
brew services start felixkratz/formulae/sketchybar
```

AeroSpace feeds the workspace highlight through `exec-on-workspace-change`
in `aerospace/aerospace.toml`. If the bar starts before that symlink
exists, `sketchybar --reload` will not find the config; run
`brew services restart felixkratz/formulae/sketchybar` once.

## Layout

| Slot | Item | Source |
|---|---|---|
| left | `1-Work 2-AI 3-Coding 4-Productivity 5-Personal 6-ParkingLot`, focused one highlighted; click switches | `plugins/aerospace.sh` |
| right | `VOL nn%` (mute), `NET ssid` (ip / off), `CPU nn%`, `RAM nn%`, `BAT nn%` (AC), clock | `plugins/volume.sh` … `clock.sh` |

No window title: it overlapped the workspace names, and the window shows
its own title bar. Nothing sits at `center`, which the notch would hide.

Bar height is 32, the height of the notch strip macOS already keeps windows
out of, so `gaps.outer.top` in aerospace.toml is 8 on the built-in display
and 40 (bar + 8) on any other monitor, where nothing else reserves the
strip. The 40 is untested until an external display is plugged in.

Right-side order follows `waybar/config.jsonc`. The menu bar on this
machine is auto-hidden, which is why volume, network, battery and clock
are in the bar at all. Temperature and fan are left out: macOS exposes
them only through `sudo powermetrics`.
