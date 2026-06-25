#!/usr/bin/env bash
# OneInchEye boot-speed trim (Tier 1-3).
#
# Safe, idempotent, and backs up every file it edits. Run on the Pi over SSH:
#   cd ~/OneInchEye && bash scripts/optimize-boot.sh
#   sudo reboot
#
# What it does:
#   Tier 1  kiosk loads the static page via file:// (no Node, no health wait),
#           network wait masked, Chromium trimmed.
#   Tier 2  firmware/kernel tweaks in config.txt + cmdline.txt.
#   Tier 3  unused services disabled.
#
# It does NOT touch the EEPROM/boot-order (risky) or remove Wi-Fi (still want
# SSH). Wi-Fi simply no longer blocks boot.
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="$(eval echo "~${USER_NAME}")"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_PATH="${REPO_ROOT}/camera-ui/public/index.html"
SERVICE_NAME="oneincheye-camera-ui.service"
STAMP="$(date +%Y%m%d-%H%M%S)"

BOOT_DIR="/boot/firmware"
[[ -f "${BOOT_DIR}/config.txt" ]] || BOOT_DIR="/boot"
CONFIG_TXT="${BOOT_DIR}/config.txt"
CMDLINE_TXT="${BOOT_DIR}/cmdline.txt"

if [[ "$(id -u)" -eq 0 && -z "${SUDO_USER:-}" ]]; then
  echo "Run as your normal user (it uses sudo where needed):"
  echo "  bash scripts/optimize-boot.sh"
  exit 1
fi

if [[ ! -f "${INDEX_PATH}" ]]; then
  echo "Missing ${INDEX_PATH} — run from the OneInchEye repo root."
  exit 1
fi

backup() {
  if [[ -f "$1" ]]; then
    sudo cp -a "$1" "$1.bak.${STAMP}"
    echo "    backup: $1.bak.${STAMP}"
  fi
}

CHROMIUM=""
for c in /usr/bin/chromium /usr/bin/chromium-browser; do
  [[ -x "$c" ]] && CHROMIUM="$c" && break
done
[[ -n "${CHROMIUM}" ]] || { echo "Chromium not found."; exit 1; }

echo "==> Tier 1: static file:// kiosk (drops Node + health wait)"

# Stop/disable the Node UI service — the page is static now.
if systemctl list-unit-files | grep -q "^${SERVICE_NAME}"; then
  sudo systemctl disable --now "${SERVICE_NAME}" 2>/dev/null || true
  echo "    disabled ${SERVICE_NAME}"
fi

# Managed kiosk launcher (full control, overwritten each run).
LAUNCHER="${USER_HOME}/.oneincheye-kiosk.sh"
cat >"${LAUNCHER}" <<EOF
#!/bin/sh
# Managed by scripts/optimize-boot.sh — do not edit by hand.
exec cage -s -- "${CHROMIUM}" \\
  --kiosk \\
  --ozone-platform=wayland \\
  --password-store=basic \\
  --no-first-run \\
  --no-default-browser-check \\
  --noerrdialogs \\
  --disable-infobars \\
  --disable-session-crashed-bubble \\
  --disable-component-update \\
  --disable-background-networking \\
  --disable-sync \\
  --disable-translate \\
  --disable-features=Translate,BackForwardCache \\
  --check-for-update-interval=31536000 \\
  --user-data-dir=/tmp/oneincheye-chromium \\
  "file://${INDEX_PATH}"
EOF
chmod +x "${LAUNCHER}"
chown "${USER_NAME}:${USER_NAME}" "${LAUNCHER}"
echo "    wrote ${LAUNCHER}"

# Point ~/.bash_profile at the launcher (backup + clean rewrite).
backup "${USER_HOME}/.bash_profile"
cat >"${USER_HOME}/.bash_profile" <<'EOF'
# Source default profile
[ -f ~/.profile ] && . ~/.profile

# >>> oneincheye kiosk >>>
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$KIOSK_LAUNCHED" ]; then
  export KIOSK_LAUNCHED=1
  exec ~/.oneincheye-kiosk.sh
fi
# <<< oneincheye kiosk <<<
EOF
chown "${USER_NAME}:${USER_NAME}" "${USER_HOME}/.bash_profile"
echo "    wrote ${USER_HOME}/.bash_profile"

# Don't block boot waiting for the network (UI is local; Wi-Fi stays for SSH).
sudo systemctl mask NetworkManager-wait-online.service 2>/dev/null || true
sudo systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true
echo "    masked *-wait-online"

echo "==> Tier 2: firmware + kernel"

# config.txt — idempotent marker block.
backup "${CONFIG_TXT}"
sudo awk '
  /# >>> oneincheye boot tuning >>>/ {skip=1}
  !skip {print}
  /# <<< oneincheye boot tuning <<</ {skip=0}
' "${CONFIG_TXT}" | sudo tee "${CONFIG_TXT}.tmp" >/dev/null
sudo mv "${CONFIG_TXT}.tmp" "${CONFIG_TXT}"
sudo tee -a "${CONFIG_TXT}" >/dev/null <<'EOF'
# >>> oneincheye boot tuning >>>
boot_delay=0
initial_turbo=60
arm_boost=1
dtoverlay=disable-bt
# <<< oneincheye boot tuning <<<
EOF
echo "    updated ${CONFIG_TXT}"

# cmdline.txt — add quiet flags. (We deliberately do NOT move console=tty1 to
# tty3 here; that can hide the kiosk on some setups. See the note after running.)
backup "${CMDLINE_TXT}"
CMD="$(cat "${CMDLINE_TXT}")"
for tok in quiet loglevel=3 logo.nologo vt.global_cursor_default=0; do
  case " ${CMD} " in
    *" ${tok} "*) ;;
    *) CMD="${CMD} ${tok}" ;;
  esac
done
echo "${CMD}" | sudo tee "${CMDLINE_TXT}" >/dev/null
echo "    updated ${CMDLINE_TXT}"

echo "==> Tier 3: disable unused services"
for unit in bluetooth.service hciuart.service ModemManager.service \
            triggerhappy.service dphys-swapfile.service \
            rpi-eeprom-update.service \
            apt-daily.timer apt-daily-upgrade.timer man-db.timer \
            e2scrub_all.timer; do
  if systemctl list-unit-files | grep -q "^${unit}"; then
    sudo systemctl disable --now "${unit}" 2>/dev/null && echo "    disabled ${unit}" || true
  fi
done

echo ""
echo "Done. Review, then reboot:"
echo "  sudo reboot"
echo ""
echo "Rollback (if needed): restore the *.bak.${STAMP} files and re-enable services."
