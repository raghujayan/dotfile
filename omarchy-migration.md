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

## Phase B -- install, manual, machine offline (you do this)

1. **Use a SECOND USB stick for the ISO.** `sda` is the backup disk;
   writing the ISO to it destroys everything Phase A just saved.
   If there is only one stick, stop -- back up to the mac mini over
   the LAN instead and re-plan.
2. Download the ISO from https://omarchy.org/ and write it with
   `caligula` (Linux) or balenaEtcher (Mac).
3. Reboot -> **F2** -> disable Secure Boot (and TPM if the installer
   complains). Save and exit.
4. **F12** -> boot the ISO stick.
5. In the installer: select `nvme0n1`, accept full-disk encryption, set
   the LUKS passphrase, user `rmenon`. Install takes 2-10 min.

## Phase C -- restore, on Omarchy first boot

1. Join Wi-Fi, mount the backup USB.
2. Verify `sha256sum -c SHA256SUMS`, then untar `secrets.tar.gz` and
   `claude.tar.gz` into `$HOME` first.
3. `git clone` HomeBoard and dotfile; rebuild the venv
   (`uv venv && uv pip install -r requirements.txt` or equivalent);
   restore `HomeBoard/wiki` from `data.tar.gz`.
4. Install Claude Code, re-auth, confirm the memory dir at
   `~/.claude/projects/-home-rmenon-HomeBoard/memory/` loads and the
   `i-have-adhd` skill is present.
5. Restore `/etc/NetworkManager/system-connections` if Wi-Fi needs it.
6. Re-enroll the fingerprint reader (not portable).
7. Verify: `ssh raghu@192.168.4.147` works, `git push` works from both
   repos, browser profiles opened, Arduino IDE sees its boards.

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
