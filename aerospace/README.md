# AeroSpace

Tiling window manager for macOS, configured to match the Hyprland binds on
the Fedora/Framework machine.

## Install

```sh
brew install --cask nikitabobko/tap/aerospace
ln -s "$PWD/aerospace.toml" ~/.aerospace.toml
```

Launch AeroSpace, then grant it Accessibility permission when prompted.

## Differences from Hyprland

| Hyprland | AeroSpace | Why |
|---|---|---|
| `SUPER` | `alt` | macOS reserves `cmd` for the system |
| `SUPER + Space` (wofi) | unbound | Spotlight already owns `cmd-space` |
| `SUPER + M` (exit session) | none | AeroSpace has no logout command |
| volume / brightness binds | none | macOS handles the media keys natively |

Reload config after editing: `alt-shift-;` then `esc`.
