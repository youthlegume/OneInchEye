#!/usr/bin/env bash
# Configure OneInchEye Pi for camera-like kiosk boot:
#   power on → autologin desktop → camera UI on :3000 → Chromium fullscreen
#
# Run on the Pi over SSH (display can be unplugged):
#   cd ~/OneInchEye && bash scripts/setup-camera-kiosk.sh
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="$(eval echo "~${USER_NAME}")"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CAMERA_UI_DIR="${REPO_ROOT}/camera-ui"
UI_URL="http://127.0.0.1:3000/"
SERVICE_NAME="oneincheye-camera-ui.service"

if [[ "$(id -u)" -eq 0 && -z "${SUDO_USER:-}" ]]; then
  echo "Run as your normal user (will use sudo where needed):"
  echo "  bash scripts/setup-camera-kiosk.sh"
  exit 1
fi

if [[ ! -f "${CAMERA_UI_DIR}/package.json" ]]; then
  echo "Missing ${CAMERA_UI_DIR}/package.json — clone the full OneInchEye repo first."
  exit 1
fi

echo "==> Installing Node.js (if needed)..."
if ! command -v node >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y nodejs npm
fi

echo "==> Installing camera-ui dependencies..."
cd "${CAMERA_UI_DIR}"
npm install --omit=dev

echo "==> Enabling desktop autologin for ${USER_NAME}..."
sudo raspi-config nonint do_boot_behaviour B4

echo "==> Creating systemd service: ${SERVICE_NAME}"
NPM_BIN="$(command -v npm)"
sudo tee "/etc/systemd/system/${SERVICE_NAME}" >/dev/null <<EOF
[Unit]
Description=OneInchEye Camera UI
After=multi-user.target
Wants=multi-user.target

[Service]
Type=simple
User=${USER_NAME}
WorkingDirectory=${CAMERA_UI_DIR}
Environment=NODE_ENV=production
Environment=HOST=127.0.0.1
Environment=PORT=3000
# Brief delay so camera / dma_heap is ready after boot
ExecStartPre=/bin/sleep 5
ExecStart=${NPM_BIN} start
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"

echo "==> Waiting for camera UI..."
for _ in $(seq 1 30); do
  if curl -sf "${UI_URL}health" >/dev/null 2>&1; then
    echo "    Camera UI is up at ${UI_URL}"
    break
  fi
  sleep 1
done

echo "==> Installing unclutter (hide mouse cursor in kiosk)..."
sudo apt install -y unclutter 2>/dev/null || true

LABWC_DIR="${USER_HOME}/.config/labwc"
mkdir -p "${LABWC_DIR}"

CHROMIUM=""
for candidate in /usr/bin/chromium /usr/bin/chromium-browser; do
  if [[ -x "${candidate}" ]]; then
    CHROMIUM="${candidate}"
    break
  fi
done
if [[ -z "${CHROMIUM}" ]]; then
  echo "Chromium not found. Install Raspberry Pi OS with Desktop, then re-run."
  exit 1
fi

LWRESPAWN="/usr/bin/lwrespawn"
if [[ ! -x "${LWRESPAWN}" ]]; then
  LWRESPAWN=""
fi

echo "==> Writing ${LABWC_DIR}/autostart"
cat >"${LABWC_DIR}/autostart" <<'AUTOSTART'
#!/bin/sh
# OneInchEye kiosk — labwc autostart (Bookworm)

# Hide cursor after 1s idle
unclutter -idle 1 -root &

# Wait for camera UI (localhost — no Wi-Fi required)
for i in $(seq 1 120); do
  if curl -sf http://127.0.0.1:3000/health >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done
AUTOSTART

if [[ -n "${LWRESPAWN}" ]]; then
  cat >>"${LABWC_DIR}/autostart" <<AUTOSTART
${LWRESPAWN} ${CHROMIUM} \\
  --kiosk \\
  --noerrdialogs \\
  --disable-infobars \\
  --no-first-run \\
  --disable-session-crashed-bubble \\
  --check-for-update-interval=31536000 \\
  --ozone-platform=wayland \\
  ${UI_URL} &
AUTOSTART
else
  cat >>"${LABWC_DIR}/autostart" <<AUTOSTART
${CHROMIUM} \\
  --kiosk \\
  --noerrdialogs \\
  --disable-infobars \\
  --no-first-run \\
  --disable-session-crashed-bubble \\
  --check-for-update-interval=31536000 \\
  --ozone-platform=wayland \\
  ${UI_URL} &
AUTOSTART
fi

chmod +x "${LABWC_DIR}/autostart"
chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME}/.config/labwc"

echo ""
echo "Done. Reboot with display connected to test:"
echo "  sudo reboot"
echo ""
echo "Service status:  systemctl status ${SERVICE_NAME}"
echo "Manual UI test:  curl http://127.0.0.1:3000/health"
echo "Kiosk autostart: ${LABWC_DIR}/autostart"
