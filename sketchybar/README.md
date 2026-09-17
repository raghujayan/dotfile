# SketchyBar

Top bar for the Mac, mirroring the waybar modules on the Fedora machine:
workspaces, focused window title, CPU, RAM. Text labels only, no nerd font,
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
| left | `1 2 3 4 5`, focused one highlighted; click switches | `plugins/aerospace.sh` |
| q (left of notch) | focused window title, max 55 chars | `plugins/title.sh` |
| right | `VOL nn%` (mute), `NET ssid` (ip / off), `CPU nn%`, `RAM nn%`, `BAT nn%` (AC), clock | `plugins/volume.sh` … `clock.sh` |

The title sits at `q` instead of `center` because on the notched display a
centred item is hidden behind the notch.

Bar height is 32, the height of the notch strip macOS already keeps windows
out of, so `gaps.outer.top` in aerospace.toml stays at 8. Verified on the
built-in display only; an external display with the menu bar auto-hidden
would have the bar over the window tops.

Right-side order follows `waybar/config.jsonc`. The menu bar on this
machine is auto-hidden, which is why volume, network, battery and clock
are in the bar at all. Temperature and fan are left out: macOS exposes
them only through `sudo powermetrics`.
