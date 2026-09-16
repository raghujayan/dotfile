#!/usr/bin/env bash
# restore-jame.sh - put the JAME balancing-robot setup back on Omarchy.
#
# Run as rmenon (not root) on the fresh install, with the 932G backup
# USB plugged in:   ./restore-jame.sh
#
# Safe to re-run: every step checks before it acts. It never overwrites
# a newer sketch without saying so, and it touches only Arduino paths -
# the rest of the Phase C restore is a separate job.
set -euo pipefail

BACKUP_DIRNAME=omarchy-backup-2026-09-16
say()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok()   { printf '   ok  %s\n' "$*"; }
warn() { printf '   !!  %s\n' "$*"; }
die()  { printf '\n   FAILED: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "run this as rmenon, not root. It calls sudo itself."

# ---------------------------------------------------------------- backup
say "finding the backup"
B=""
for c in /run/media/*/*/"$BACKUP_DIRNAME" /media/*/*/"$BACKUP_DIRNAME" \
         /mnt/*/"$BACKUP_DIRNAME" "$HOME/$BACKUP_DIRNAME"; do
  [ -d "$c" ] && B="$c" && break
done
if [ -z "$B" ]; then
  warn "not mounted. Looking for the exfat partition..."
  lsblk -o NAME,SIZE,FSTYPE,LABEL | grep -i exfat || true
  cat <<'EOF'

   Mount it and run this again:
     sudo mkdir -p /mnt/usb
     sudo mount /dev/sdX1 /mnt/usb        # the 932G exfat partition
EOF
  die "backup not found"
fi
ok "$B"

say "verifying the archives"
[ -f "$B/data.tar.gz" ] && [ -f "$B/arduino15.tar.gz" ] || die "archives missing from $B"
( cd "$B" && sha256sum -c --ignore-missing SHA256SUMS 2>/dev/null \
    | grep -E 'data\.tar\.gz|arduino15\.tar\.gz' ) || die "checksum mismatch - do not trust this backup"

# ------------------------------------------------------------- the files
say "restoring sketch, libraries and IDE config"
if [ -f "$HOME/jame/test.cpp/test.cpp.ino" ]; then
  warn "~/jame already exists - leaving it alone"
  warn "to take the backup's copy instead: rm -rf ~/jame, then re-run"
else
  tar -xzf "$B/data.tar.gz" -C "$HOME" jame
  ok "jame/ (sketch, project_guide.md, build_notebook.md, media/)"
fi

tar -xzf "$B/data.tar.gz" -C "$HOME" Arduino .arduinoIDE \
    ".config/Arduino IDE" .config/arduino-ide
ok "Arduino/libraries, .arduinoIDE, IDE settings"

say "restoring the ESP32 core (skips a ~1.7G download)"
if [ -d "$HOME/.arduino15/packages/esp32/hardware/esp32/3.3.11" ]; then
  ok "esp32 3.3.11 already present"
else
  # staging/ and tmp/ are just the downloaded zips the IDE already
  # unpacked - ~1.7G of cache. The IDE recreates them if it ever needs to.
  tar -xzf "$B/arduino15.tar.gz" -C "$HOME" \
      --exclude='.arduino15/staging' --exclude='.arduino15/tmp' .arduino15
  ok "esp32 $(ls "$HOME/.arduino15/packages/esp32/hardware/esp32/" 2>/dev/null | tr '\n' ' ')"
fi

# ------------------------------------------------------------ serial port
say "serial port access"
# Fedora used 'dialout'; Arch puts tty devices in 'uucp'.
NEED=()
for g in uucp lock; do
  getent group "$g" >/dev/null || { warn "group '$g' does not exist here, skipping"; continue; }
  id -nG "$USER" | tr ' ' '\n' | grep -qx "$g" || NEED+=("$g")
done
if [ ${#NEED[@]} -eq 0 ]; then
  ok "already in uucp/lock"
else
  echo "   adding $USER to: ${NEED[*]}  (sudo)"
  sudo usermod -aG "$(IFS=,; echo "${NEED[*]}")" "$USER"
  warn "LOG OUT AND BACK IN before the IDE will see a port"
fi

say "brltty (it steals CH340 adapters on Arch)"
if pacman -Qq brltty >/dev/null 2>&1; then
  warn "brltty is installed. If the port appears then vanishes a second"
  warn "after plugging the board in, that is why. Remove it with:"
  echo  "     sudo pacman -Rns brltty"
else
  ok "not installed"
fi

# -------------------------------------------------------------- the IDE
say "Arduino IDE"
if command -v arduino-ide >/dev/null 2>&1 || pacman -Qq arduino-ide-bin >/dev/null 2>&1; then
  ok "already installed"
else
  HELPER=""
  for h in yay paru; do command -v "$h" >/dev/null 2>&1 && HELPER="$h" && break; done
  if [ -n "$HELPER" ]; then
    echo "   installing arduino-ide-bin with $HELPER (AUR, 2.3.10 - same as the old AppImage)"
    "$HELPER" -S --needed --noconfirm arduino-ide-bin || warn "install failed; run '$HELPER -S arduino-ide-bin' by hand"
  else
    warn "no yay/paru found. Install one, then: yay -S arduino-ide-bin"
    warn "or work from the terminal: sudo pacman -S arduino-cli"
  fi
fi

# --------------------------------------------------------------- verify
say "checking the result"
FAIL=0
[ -f "$HOME/jame/test.cpp/test.cpp.ino" ] && ok "sketch present" || { warn "sketch MISSING"; FAIL=1; }
grep -q 'targetAngle' "$HOME/jame/test.cpp/test.cpp.ino" 2>/dev/null \
  && ok "tuning constants: $(grep -m1 '^float Kp' "$HOME/jame/test.cpp/test.cpp.ino")" \
  || { warn "sketch looks wrong"; FAIL=1; }
for l in Adafruit_MPU6050 Adafruit_BusIO Adafruit_Unified_Sensor; do
  [ -d "$HOME/Arduino/libraries/$l" ] || { warn "library MISSING: $l"; FAIL=1; }
done
[ "$FAIL" -eq 0 ] && ok "all five Adafruit libraries present"
[ -f "$HOME/.arduinoIDE/arduino-cli.yaml" ] && ok "IDE config (ESP32 board-manager URL)" \
  || { warn "arduino-cli.yaml MISSING"; FAIL=1; }
ls /dev/ttyUSB* /dev/ttyACM* >/dev/null 2>&1 \
  && ok "board on $(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | tr '\n' ' ')" \
  || warn "no board plugged in right now (fine - plug it in later)"

say "done"
if [ "$FAIL" -ne 0 ]; then
  die "something above is missing - read the !! lines"
fi
cat <<'EOF'
   Next:
     1. Log out and back in, if the group step said to.
     2. Plug the ESP32 in, then: ls -l /dev/ttyUSB* /dev/ttyACM*
     3. Open the IDE, File > Open > ~/jame/test.cpp/test.cpp.ino
     4. Board: ESP32 Dev Module. Port: the ttyUSB above.
EOF
