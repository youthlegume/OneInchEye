# OneInchEye Camera UI

Web UI for IMX283 camera control, designed for **480×480 kiosk display** on the Pi.

## Quick start (dev)

```bash
cd camera-ui
npm install
npm start
```

Open `http://127.0.0.1:3000` in a browser.

## Kiosk boot (production)

From the repo root on the Pi (SSH, display unplugged):

```bash
cd ~/OneInchEye
bash scripts/setup-camera-kiosk.sh
sudo reboot
```

After reboot with the display connected, the Pi should autologin to the desktop and open this UI fullscreen in Chromium with no browser chrome.

See **scripts/setup-camera-kiosk.sh** for what it configures:

- systemd service (`oneincheye-camera-ui.service`) — starts `npm start` at boot
- `~/.config/labwc/autostart` — waits for `http://127.0.0.1:3000`, then launches Chromium kiosk
- Desktop autologin for your user
- Optional cursor hide (`unclutter`)

Uses **localhost** so the UI comes up without waiting for Wi‑Fi.

## Requirements

- Raspberry Pi OS **with Desktop** (Bookworm / labwc)
- Node.js 18+ (`sudo apt install -y nodejs npm`)
- OneInchEye camera stack working (`rpicam-still` test passes)

## Next steps (UI)

This folder is a placeholder shell. Replace `public/index.html` and add API routes in `server.js` for:

- Live view (Picamera2 MJPEG or WebRTC)
- ISO, shutter, exposure controls
- Capture / record
