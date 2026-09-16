# Fedora 44 -> Omarchy migration (Framework Laptop 13, i7-1165G7)

Written 2026-09-16. This is NOT an upgrade. Omarchy has no in-place path
from Fedora. It is a fresh Arch-based install that **wipes nvme0n1**.

This file lives in `raghujayan/dotfile` on GitHub and is copied to the USB
disk, because the laptop it describes gets erased. Read it from the mac
mini or a phone during the install.

## Machine facts (verified 2026-09-16)

- Framework Laptop 13, 11th gen i7-1165G7, BIOS 03.25, UEFI boot.
- `nvme0n1` 476.9G: p1 600M vfat /boot/efi, p2 2G ext4 /boot,
  p3 474.4G btrfs / and /home. **No LUKS today.**
- 26G used of 475G. Secure Boot is **enabled** -> must be disabled.
- USB backup disk `sda` 932G exfat, 930G free, currently mounted.
- HomeBoard's 6.0G is `.venv` only. Rebuildable; not backed up.
- The board itself runs on the mac mini (192.168.4.147) since 2026-09-14,
  so wiping this laptop causes no board downtime.

## Assumptions

- Full wipe of nvme0n1. No dual boot (Omarchy does not support it
  officially).
- Same username `rmenon` on the new system, so restored paths line up.
- Omarchy encrypts the disk by default and this is required -- the setup
  auto-logs-in after LUKS unlock. You will choose a passphrase you did
  not have before. **Write it down before typing it.**

## Phase A -- backup, on Fedora (Claude runs this, ~20 min)

1. Review and commit the two dirty files, push both repos:
   - `HomeBoard/wiki_index.py`
   - `dotfile/claude/CLAUDE.md`
2. Write reference lists into the backup so the new box can be rebuilt:
   `rpm -qa --qf '%{NAME}\n' | sort`, `flatpak list`, `dnf history list`,
   `nmcli connection show`, `lsblk`, `systemctl --user list-unit-files`.
3. Back up with **tar, not rsync** -- the USB is exfat and drops
   ownership, modes and symlinks; tar keeps them inside the archive.
   Three archives so one bad checksum does not cost everything:
   - `secrets.tar.gz`: `.ssh` `.tokens` `.gitconfig` `.bashrc`
     `.bash_profile` `.pki` `.local/share/keyrings`
   - `claude.tar.gz`: `.claude` `.claude.json` `.qmd`
     (memory dir, settings, the `i-have-adhd` skill)
   - `data.tar.gz`: `.config` (mozilla, chrome, board,
     copilot-money-cli) `Arduino` `.arduinoIDE` `jame` `Pictures`
     `ai-by-hand` `Downloads` `board.tar.gz` `HomeBoard/wiki`
   - `etc-nm.tar.gz` via sudo: `/etc/NetworkManager/system-connections`
     (Wi-Fi passwords for `menonhome`)
4. Skipped on purpose: `.cache` (7.9G), `HomeBoard/.venv` (6.0G),
   `dotenv` (upstream clone), the Arduino AppImage (re-download).
   `.arduino15` (7.5G) is included -- slow to rebuild, space is free.
5. `sha256sum` every archive to `SHA256SUMS` on the USB; `tar -tzf`
   spot-check each one before trusting it.
6. Copy this file to the USB root.

## Phase C — restore, on Omarchy first boot

1. Join Wi-Fi. Omarchy uses **iwd**, not NetworkManager — run `impala`
   (or `iwctl station wlan0 connect menonhome`). `etc-nm.tar.gz` is a
   *reference* for the passphrase, not a drop-in: untar it and read
   `psk=` out of `menonhome.nmconnection`.
2. Plug the 932G backup disk back in and mount it by hand; do not
   assume it automounts:
   ```
   lsblk                                  # find the 932G exfat partition
   sudo mkdir -p /mnt/usb && sudo mount /dev/sdX1 /mnt/usb
   cd /mnt/usb/omarchy-backup-2026-09-16 && sha256sum -c SHA256SUMS
   ```
   exfat is in the kernel; no package needed.
3. **Do not extract `secrets.tar.gz` or `data.tar.gz` into `$HOME`
   wholesale.** Both carry Fedora/GNOME dotfiles that would overwrite
   Omarchy's own. `secrets.tar.gz` has `.bashrc` and `.bash_profile`,
   and Omarchy's versions source its defaults and start Hyprland on
   tty1 — clobbering them drops you to a bare shell. Stage and pick:
   ```
   mkdir -p ~/restore && tar -xzf secrets.tar.gz -C ~/restore
   cp -a ~/restore/.ssh ~/restore/.tokens ~/restore/.gitconfig ~/restore/.pki ~/
   mkdir -p ~/.local/share && cp -a ~/restore/.local/share/keyrings ~/.local/share/
   chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_ed25519
   ```
   Diff `~/restore/.bashrc` against the new one by hand later; take only
   the aliases you want.
4. `claude.tar.gz` is safe whole: `tar -xzf claude.tar.gz -C ~`.
5. `data.tar.gz` by named path only, never the whole archive — it holds
   all of `.config`, GNOME's `gtk-3.0`, `dconf` and `mimeapps.list`
   included, which would undo Omarchy's theming:
   ```
   tar -xzf data.tar.gz -C ~ .config/mozilla .config/google-chrome \
       .config/board .config/copilot-money-cli Arduino .arduinoIDE \
       ".config/Arduino IDE" .config/arduino-ide \
       jame Pictures ai-by-hand Downloads board.tar.gz HomeBoard/wiki
   ```
   `.arduino15` likewise: `tar -xzf arduino15.tar.gz -C ~ .arduino15`.
6. Clone and rebuild:
   ```
   git clone git@github.com:raghujayan/HomeBoard.git
   git clone git@github.com:raghujayan/dotfile.git
   cd HomeBoard && python -m venv .venv && .venv/bin/pip install -r requirements.txt
   ```
   `requirements.txt` does **not** list torch, which `wiki_index.py`
   needs. The exact set that worked is in
   `refs/homeboard-venv-freeze.txt` (100 packages, Python 3.14.3) —
   use it if the wiki indexer misbehaves.
7. Install Claude Code, re-auth, confirm `~/.claude/projects/
   -home-rmenon-HomeBoard/memory/MEMORY.md` and
   `~/.claude/skills/i-have-adhd/SKILL.md` came back.
8. Re-enroll the fingerprint reader — `fprintd-enroll`, not portable.
9. Verify: `ssh raghu@192.168.4.147`, `git push` from both repos,
   browser profiles open, Arduino IDE sees its boards.

Reference lists for rebuilding by hand are in `refs/`: `rpm-packages.txt`
(Fedora names, so translate to pacman), `flatpak.txt`, `dnf-history.txt`,
`system-units.txt`, `user-units.txt`, and `burn-omarchy.sh` itself.

## The Arduino side (jame, the balancing robot)

Test-restored on 2026-09-16 before the wipe: `jame`, `Arduino` and
`.arduinoIDE` extract from `data.tar.gz` and `diff -r` clean against the
originals. `test.cpp.ino` is byte-identical, so the tuned constants
survive - `Kp 18.0 / Ki 0.0 / Kd 0.5`, `gyroYoffset -0.0321`,
`targetAngle 12.00`. The esp32 core extracts from `arduino15.tar.gz`.

What is where:

- `jame/` - the sketch `test.cpp/test.cpp.ino`, `project_guide.md`,
  `build_notebook.md`, and the wiring images in `media/`. The only
  sketch of yours on the machine; everything else under `Arduino/` is
  library examples.
- `Arduino/libraries/` - Adafruit BusIO, GFX, SSD1306, MPU6050,
  Unified_Sensor.
- `.arduino15/packages/esp32/hardware/esp32/3.3.11` - the ESP32 core.
  Restoring it from the archive skips a ~1.7G re-download.
- `.arduinoIDE/arduino-cli.yaml` - holds the ESP32 board-manager URL
  and points `data` at `~/.arduino15`, `user` at `~/Arduino`. Those are
  absolute paths under `/home/rmenon`, which is why Phase B keeps the
  username `rmenon`. A different username silently breaks them.

The data migrates cleanly. The hitches on the other side are all
environmental:

1. **Serial port group.** Fedora puts you in `dialout` (you are, gid
   18). Arch does not use it - `ttyUSB*`/`ttyACM*` belong to **`uucp`**.
   Without this the IDE shows no port and blames the board:
   `sudo usermod -aG uucp,lock rmenon`, then log out and back in.
2. **brltty.** It is installed here and harmless, but on Arch its udev
   rules grab CH340-based USB-serial adapters and the port vanishes a
   second after you plug the board in. If the port flaps, remove it:
   `sudo pacman -Rns brltty`.
3. **The IDE itself is not in the backup** - the AppImage was skipped
   deliberately, and it did not need backing up. Checked against the
   repos on 2026-09-16: AUR carries `arduino-ide-bin` at **2.3.10**,
   the same version as the AppImage here, and `arduino-cli` 1.5.1 is
   in `extra`. So `yay -S arduino-ide-bin`, or
   `sudo pacman -S arduino-cli` to work from the terminal. The old
   AppImage is a fallback if you keep a copy, but it needs `fuse2`. Restore `.arduinoIDE` and
   `.arduino15` *before* first launch so it finds the core and does not
   offer to download everything again.
4. **Check the board is seen** before blaming anything else:
   `ls -l /dev/ttyUSB* /dev/ttyACM*`, and `dmesg | tail` on plug-in.
   The kernel drivers (`cp210x`, `ch341`, `ftdi_sio`) ship with Arch's
   default kernel; nothing to install. No custom udev rules exist on
   this machine, so there are none to carry over.

## Off-machine copies

- This file: GitHub `raghujayan/dotfile`, USB root, and the mac mini.
- `secrets.tar.gz`, `claude.tar.gz`, `etc-nm.tar.gz`, `SHA256SUMS`:
  also at `raghu@192.168.4.147:~/omarchy-backup/`, so the irreplaceable
  66M does not sit on one stick.

## Risks

- exfat + rsync loses metadata -> tar is mandatory.
- One USB stick is not enough; the ISO write would eat the backup.
- Secure Boot on -> the ISO silently will not boot until it is off.
- New LUKS passphrase: forget it and the disk is gone. The USB backup
  is the only recovery. Record it off-machine first.
- This Claude Code session dies at the reboot in Phase B. Everything
  needed afterwards must be in this file, on GitHub and on the USB.
- `.claude` must be restored before Claude is useful again.

## Status log

**2026-09-16 10:45 — Phase A complete and verified.**
Backup lives at `<USB DISK>/omarchy-backup-2026-09-16/`, all five
archives pass `sha256sum -c`, zero tar warnings:

| archive | size | holds |
|---|---|---|
| `secrets.tar.gz` | 6K | `.ssh/id_ed25519`, `.tokens`, git and bash config, `.pki`, keyrings |
| `claude.tar.gz` | 66M | `.claude` (memory dir, `i-have-adhd` skill), `.claude.json`, `.qmd` |
| `data.tar.gz` | 1.6G | `.config` (mozilla, chrome, board, copilot-money-cli), Arduino, jame, Pictures, Downloads, HomeBoard/wiki |
| `arduino15.tar.gz` | 3.3G | `.arduino15` board packages |
| `etc-nm.tar.gz` | 505B | Wi-Fi profiles incl. `menonhome` |

Reference lists (rpm, flatpak, dnf history, units, nmcli) are in
`refs/`. Both repos are committed and pushed.

ISO: `omarchy-4.0.4.iso`, 6.19G, downloaded to `~/` and SHA-256 verified
against `iso.omarchy.org` —
`ddeded2758c48318d201dfdac905ecb28f570441883f0c052ea3cd5d05acf92d`.

**Blocked: Phase B step 2.** The 31G "Flash Disk" (serial CE98A677) is
write-protected in hardware. `dd` reported 255 MB/s into page cache and
then failed at fsync; the kernel log is unambiguous —
`Sense Key : Data Protect`, `Add. Sense: Write protected`,
`Write Protect is on`. Nothing was written; it still holds the old
Ubuntu 18.04.4 image. Either a physical lock slider is engaged, or the
controller has latched read-only for good, which is how worn sticks die.

Next action: clear the lock or find another stick (8G+), then rerun
`~/burn-omarchy.sh` under sudo. That script re-checks the serial, so
edit the guard if the replacement stick is a different one.

**2026-09-16 11:05 — installer stick is written and verified.**

Three sticks were tried. Worth recording, because the failure was not
obvious from the outside:

- Generic "Flash Disk" CE98A677, 31.3G — **dead**. Its Mode Sense
  reports `Write Protect is off` while every actual write comes back
  `Not Ready` then `Data Protect / Write protected` at sector 0. A
  worn controller latching read-only. A plain `dd` hides this: it hit
  255 MB/s writing into page cache and only failed at fsync. The burn
  script now writes one 4K block with `oflag=direct` and reads it back
  before touching anything, so a stick like this fails in a second.
- SanDisk Cruzer Contour U3 3550010EEB6079AB, 30.4G — **used**. Held a
  BitLocker volume labelled `DESKTOP-T8STEP1 VAIDEHI 5/22/2018` whose
  password was long forgotten; wiped with permission. Wrote at
  8.7 MB/s over 708 s and the read-back hash matches the ISO.

`~/burn-omarchy.sh <SERIAL>` resolves a serial to its device itself, so
the `sdb`/`sdc` shuffle between replugs cannot mislead it, and it
refuses the backup disk (`0700199D3BA32D10`) outright.

## Phase B — from here, with the machine offline

1. **Unplug the 932G backup disk.** Leave only the Cruzer in. That
   disk is the one copy of everything irreplaceable, and a mis-click
   in the installer's disk picker is the only way left to lose it.
   Plug it back in for Phase C.
2. Reboot. At the Framework logo press **F2** for setup.
3. Security -> Secure Boot -> **Disabled**. It is enabled today and the
   Omarchy ISO will not boot until it is off. Save and exit (F10).
4. Press **F12** for the boot menu, pick the Cruzer (UEFI entry).
5. Omarchy 4.0.4 asks about five things. Answers:
   - disk: `nvme0n1` (476.9G WDC PC SN730). **Not** either USB.
   - full-disk encryption: yes. Choose a LUKS passphrase and write it
     on paper before typing it. There is no encryption today, so this
     is new, and forgetting it means the disk is gone.
   - user: `rmenon`, so every restored path lines up.
   - hostname: `framework`, if it asks; otherwise
     `hostnamectl set-hostname framework` afterwards. Keeps the mac
     mini's ssh config valid.
   - timezone/locale: as before.
6. Install runs 2-10 minutes, then reboots into Hyprland.

Note: the Cruzer is a U3 stick and exposes a small fake CD-ROM
(`/dev/sr0`, "LIVEU3") from firmware. If F12 lists two Cruzer entries,
take the larger/UEFI one, not the CD.
