# Hyprland

Config for the Framework 13 running Fedora 44.

Install: copy (or symlink) these into `~/.config/hypr/`. `KEYS.txt` is the
cheat-sheet shown at login and on `SUPER + H`, so keep it in step with the
binds in `hyprland.conf`.

`fanctrl-cycle.sh` needs `fw-fanctrl` from the COPR `zktaiga/fw-fanctrl`:

```sh
sudo dnf copr enable zktaiga/fw-fanctrl
sudo dnf install fw-fanctrl framework-tool
sudo systemctl enable --now fw-fanctrl
```

Display scale is 1.5666667, not 1.5 — 1504 does not divide evenly by 1.5, so
Hyprland snaps to the nearest scale giving an integer logical size (1440x960).
