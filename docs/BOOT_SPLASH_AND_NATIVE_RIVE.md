# Boot Splash (Bootloader + Plymouth) and Native Rive Direction

This document covers two topics for the OneInchEye CM4 kiosk configuration:

1. **Boot visuals** — Custom bootloader splash + Plymouth theming for a polished power-on experience
2. **Native Rive direction** — Product consensus on native Rive vs web WASM for the camera UI

---

## Section 1: Boot Visuals (Bootloader + Plymouth)

Eliminate the firmware rainbow splash and boot text by adding early bootloader graphics and a custom Plymouth theme on Raspberry Pi OS Bookworm/Trixie Desktop.

### Goal

- **Early splash** — Replace firmware rainbow with a TGA image via bootloader config
- **Plymouth theme** — Show custom graphics during boot until the kiosk UI is ready
- **Seamless transition** — Hold Plymouth until the camera UI health endpoint responds (or match the UI's first frame for visual continuity)

### Prerequisites

- Raspberry Pi OS **Bookworm or Trixie Desktop** (64-bit recommended)
- OneInchEye camera-ui kiosk setup completed (see `camera-ui/README.md`)
- `/boot/firmware/` paths (Bookworm+ standard)

---

### Step 1: Early Bootloader Splash (Kill Rainbow + Pre-Plymouth Text)

Install bootloader splash support:

```bash
sudo apt update
sudo apt install -y rpi-splash-screen-support
```

Create or obtain a **TGA image** for the bootloader splash (e.g. `opal-bootloader.tga`). Place it in `/boot/firmware/`:

```bash
sudo cp /path/to/opal-bootloader.tga /boot/firmware/splash.tga
```

Configure the bootloader splash via `raspi-config`:

```bash
sudo raspi-config nonint do_boot_splash 0
```

This sets `splash.tga` as the early splash and disables the rainbow. Verify `/boot/firmware/config.txt` includes:

```ini
disable_splash=1
```

**Note:** On some versions `disable_splash=1` disables the firmware rainbow but keeps your custom splash (the bootloader splash support tools manage the actual splash rendering). If you see text flicker after splash, proceed to Plymouth in Step 2.

---

### Step 2: Install Plymouth

```bash
sudo apt install -y plymouth rpd-plym-splash
```

`rpd-plym-splash` provides Raspberry Pi-specific Plymouth integration.

---

### Step 3: Create a Custom Plymouth Theme (`opal`)

Plymouth themes live in `/usr/share/plymouth/themes/`. We'll create an `opal` theme by cloning the existing `pix` theme (static PNG) or using a script plugin for looping frames.

#### Option A: Static PNG (Simple)

```bash
sudo mkdir -p /usr/share/plymouth/themes/opal
cd /usr/share/plymouth/themes/opal
```

Copy a base theme:

```bash
sudo cp -r /usr/share/plymouth/themes/pix/* /usr/share/plymouth/themes/opal/
```

Replace the splash image:

```bash
# Place your PNG (e.g. opal-splash.png) into the opal theme folder
sudo cp /path/to/opal-splash.png /usr/share/plymouth/themes/opal/splash.png
```

Edit the theme file:

```bash
sudo nano /usr/share/plymouth/themes/opal/opal.plymouth
```

Content:

```ini
[Plymouth Theme]
Name=opal
Description=Opal OneInchEye Camera Splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/opal
ScriptFile=/usr/share/plymouth/themes/opal/opal.script
```

Create a simple script (for a static PNG):

```bash
sudo nano /usr/share/plymouth/themes/opal/opal.script
```

Content:

```plymouth
# Static splash for Opal
Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);

logo.image = Image("splash.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);
```

#### Option B: Looping Animation Frames (Advanced)

For frame-based animation, place numbered PNGs (`frame-0001.png`, `frame-0002.png`, ...) in the theme directory and extend the script to cycle through them. See the [Plymouth scripting guide](https://www.freedesktop.org/wiki/Software/Plymouth/Scripts/) for syntax.

---

### Step 4: Set Boot Command Line Options

Edit `/boot/firmware/cmdline.txt` (single line, append to existing parameters):

```bash
sudo nano /boot/firmware/cmdline.txt
```

Add these options at the end (space-separated):

```
quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0 logo.nologo
```

- `quiet` — Suppress kernel messages
- `splash` — Enable Plymouth
- `plymouth.ignore-serial-consoles` — Prevent serial console text from breaking splash
- `vt.global_cursor_default=0` — Hide text cursor
- `logo.nologo` — Disable Tux logo

**Example full line:**

```
console=serial0,115200 console=tty1 root=PARTUUID=xxxxxxxx-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0 logo.nologo
```

---

### Step 5: Set the Default Plymouth Theme

```bash
sudo plymouth-set-default-theme --rebuild-initrd opal
```

If `--rebuild-initrd` is not available or fails:

```bash
sudo plymouth-set-default-theme opal
sudo update-initramfs -u
```

Verify:

```bash
plymouth-set-default-theme
```

Should output: `opal`

---

### Step 6: Hold Plymouth Until Camera UI is Ready

Create a systemd service that holds Plymouth until the kiosk UI health endpoint responds.

Create `/etc/systemd/system/opal-plymouth-hold.service`:

```bash
sudo nano /etc/systemd/system/opal-plymouth-hold.service
```

Content:

```ini
[Unit]
Description=Hold Plymouth until Opal camera UI is ready
After=plymouth-start.service
Before=plymouth-quit.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/wait-for-camera-ui.sh
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
```

Create the wait script:

```bash
sudo nano /usr/local/bin/wait-for-camera-ui.sh
```

Content:

```bash
#!/bin/bash
# Wait for camera UI health endpoint before quitting Plymouth

HEALTH_URL="http://127.0.0.1:3000/health"
MAX_WAIT=30
INTERVAL=0.5

elapsed=0
while [ $(echo "$elapsed < $MAX_WAIT" | bc) -eq 1 ]; do
    if curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
        echo "Camera UI ready at $HEALTH_URL"
        plymouth quit
        exit 0
    fi
    sleep $INTERVAL
    elapsed=$(echo "$elapsed + $INTERVAL" | bc)
done

echo "Camera UI did not respond within $MAX_WAIT seconds, quitting Plymouth anyway"
plymouth quit
exit 0
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/wait-for-camera-ui.sh
```

Enable the service:

```bash
sudo systemctl enable opal-plymouth-hold.service
```

**Note:** This assumes the camera-ui server exposes `GET /health` (see `camera-ui/server.js` to add this endpoint if not present). Example health endpoint:

```javascript
// In camera-ui/server.js
app.get('/health', (req, res) => {
  res.json({ ok: true });
});
```

---

### Step 7: Reboot and Test

```bash
sudo reboot
```

Expected boot sequence:

1. Early TGA splash (replaces rainbow)
2. Plymouth `opal` theme (custom graphics)
3. Plymouth holds until camera UI `/health` responds
4. Plymouth quits, kiosk UI appears

---

### Fallback: Visual Continuity Without Hold Service

If the hold service is not used (or fails), ensure **visual continuity** by matching the **last frame of your Plymouth splash** to the **first frame rendered by the camera UI**. This creates the illusion of a seamless transition even if Plymouth quits before the UI is fully loaded.

Design the Plymouth splash PNG / final frame to match your UI's initial state (e.g. same background color, logo placement).

---

### Troubleshooting

- **Plymouth not showing:** Check that `quiet splash` are in `cmdline.txt` and the theme is set with `plymouth-set-default-theme opal`.
- **Text flicker during boot:** Ensure `plymouth.ignore-serial-consoles vt.global_cursor_default=0 logo.nologo` are in `cmdline.txt`.
- **Plymouth holds forever:** Check camera UI health endpoint is accessible: `curl http://127.0.0.1:3000/health` from the Pi. Adjust timeout in `wait-for-camera-ui.sh` if needed.
- **Initramfs not updated:** After changing theme, always run `sudo update-initramfs -u`.

---

## Section 2: Native Rive Direction

### Product Discussion Consensus (2026-09-24)

Based on pi-sim research and CSS/Rive/wired shutter benchmarks, the following direction was agreed upon for the OneInchEye camera UI:

#### 1. **Native Rive (C++/OpenGL/EGL) is on the table**

The camera UI web stack is **not locked** — native Rive is a viable option.

**Why:** Native Rive offers a **significant startup performance advantage** over Chromium + Rive WASM on the target CM4 hardware.

#### 2. **Expected performance win**

Native Rive (C++/OpenGL/EGL host) is expected to save **~1–2+ seconds** on the metric: *"desktop/services up → face on screen"* compared to Chromium + Rive WASM.

**Caveat:** Cold power-on time is still dominated by:

- CM4 firmware/kernel bring-up
- systemd service startup
- Intentional kiosk startup waits (e.g. `ExecStartPre` sleep in existing scripts)

The ~1–2 s win applies to the *UI rendering phase*, not total power-on time. However, shaving 1–2 s off the visible UI startup improves perceived responsiveness.

#### 3. **Rive-in-browser role**

If Rive is used in the web UI, it is **optional decoration only** — not for boot chrome (splash/loading) or shutter acknowledgment.

**Rationale:** Chromium + WASM Rive adds significant latency (see benchmarks: ~986.9 ms cold vs ~235.0 ms native on test hardware). Critical UI elements (shutter feedback, first paint) should not wait for WASM runtime.

#### 4. **Keep CSS (or native widgets) for first-paint speed**

Use **CSS** (or native UI widgets if going full native) for:

- **Menus** (Shoot / Gallery / Settings)
- **Shutter button** and immediate visual acknowledgment

**Why:** CSS-based UI paints **dramatically faster** than Rive-in-browser (see benchmarks: ~41.2 ms cold vs ~986.9 ms for Rive webgl2). When using a web shell (Chromium kiosk), CSS ensures instant first paint.

#### 5. **Shutter path is independent of UI animation**

Shutter capture goes through the **capture daemon** (`rpicam-still` / Picamera2), not the Rive animation layer.

**Implementation:**

- **Web UI:** Shoot button → `POST /api/capture` → server calls `rpicam-still` or Picamera2
- **Native UI:** Shoot button → direct libcamera/rpicam API call

Rive (if used) may provide visual feedback (button animation, shutter effect), but the capture timing is controlled by the daemon/API.

#### 6. **Validate real shutter timing on CM4 hardware**

**Critical:** All UI/shutter benches to date were run on **x86 KVM guest with software GL** (see `REPORT_2911.md`). These numbers are **not representative** of CM4+IMX283 performance.

**Next step:** Run the same A/B harness on **actual Pi hardware** with the real ISP stack to measure true click → JPEG latency.

**Why:** Pi simulators (QEMU, Docker, etc.) **cannot meaningfully simulate** the CM4 CSI → RP1/CFE/Unicam → Pi ISP → `rpicam-still` pipeline. Timing numbers from simulators are only useful for relative UI comparisons, not absolute camera performance.

#### 7. **Package/reuse the A/B harness**

The CSS vs Rive (web + native) harness built during pi-sim research (`opal-rive-bench/`) should be **reused for CM4 runs**:

- Same `.riv` asset (`off_road_car.riv` or final camera UI `.riv`)
- Same metrics (process start → first frame)
- Chromium+WASM bench vs native OpenGL bench
- Wired shutter path bench with real `rpicam-still`

This enables apples-to-apples comparison of web vs native on the target platform.

#### 8. **Research summary: Best off-device path is host `/api/capture` stub**

When developing/testing **without physical CM4** hardware, the best approach is:

- **Host-side capture stub** (`/api/capture` → sleep + write JPEG)
- Tunable synthetic delay to model IMX283 capture time
- Validates UI→API orchestration without pretending to have real ISP

**Pi simulators ranking:**

| Option | Camera reality | Suitability for shutter benches |
|--------|----------------|----------------------------------|
| Host stub (x86) | Fake (tunable delay) | **Excellent** for UI/API timing |
| v4l2loopback | Fake V4L2 | Situational (if using getUserMedia) |
| libcamera virtual/vimc | Fake libcamera | Not Pi ISP, generic only |
| QEMU virt/raspi | **None** | ARM packaging smoke test only |

See `REPORT_2911.md` (uploaded) for full simulator evaluation.

**Key takeaway:** QEMU raspi machines and x86 "Pi Desktop" images have **no CSI camera support** — they boot the OS but cannot model the OneInchEye IMX283 / `rpicam-still` / Picamera2 stack. True shutter latency must be measured on hardware.

#### 9. **CSS vs Rive web vs native benchmark summary**

From `REPORT-css-vs-rive_aba5.md` (uploaded):

| UI Path | Cold (process → first frame) | Warm (nav → first frame) |
|---------|-------------------------------|--------------------------|
| **CSS menu** (Chromium) | ~397.0 ms | ~15.9 ms |
| **Rive webgl2** (Chromium) | ~1363.0 ms | ~662.9 ms |
| **Rive native** (C++/GL) | ~235.0 ms | ~210.7 ms |

**Interpretation:**

- CSS is **fastest for first paint** (~24× faster than Rive web on cold nav metric)
- Native Rive beats Rive web by **~4–6×** depending on metric
- These are **VM/software-GL numbers** — re-bench on device with real GPU

#### 10. **Wired shutter path summary**

From `REPORT_47fa.md` (uploaded):

| UI | Stub delay | click→file |
|----|------------|------------|
| CSS | 0 ms | 18.5 ms |
| Rive-shell | 0 ms | 211.4 ms |
| CSS | 150 ms | 168.7 ms |
| Rive-shell | 150 ms | 325.5 ms |

**Caveat:** The Rive-shell page showed a **~60–150 ms gap** between ack and file even though **server elapsed matched CSS**. This gap is **client-side**: WebGL2 Rive keeps the main thread busy, delaying fetch body parsing.

**Takeaway:** The shutter API itself is not slower with Rive — observation/parsing is. Prefer **server elapsed** or a **Worker/high-priority fetch path** when comparing backend latency.

---

### Recommended Next Steps

1. **Camera UI health endpoint:** Add `GET /health` to `camera-ui/server.js` if not present (for Plymouth hold service).
2. **Design Plymouth splash assets:** Create TGA (bootloader) + PNG (Plymouth theme) that match or transition to the UI's first frame.
3. **Native Rive evaluation:** Prototype a minimal native Rive player (C++/OpenGL/EGL) on the CM4, measure startup vs Chromium kiosk.
4. **Shutter timing on hardware:** Run wired shutter bench (`opal-rive-bench/wired/`) on CM4+IMX283 with real `rpicam-still`.
5. **A/B final decision:** Compare CSS menu + native Rive decoration vs full Chromium kiosk + Rive web, optimizing for first-paint and shutter acknowledgment speed.

---

## References

- **Pi-sim research:** `uploads/REPORT_2911.md` (simulator evaluation, IMX283 cannot be meaningfully simulated)
- **CSS vs Rive bench:** `uploads/REPORT-css-vs-rive_aba5.md` (x86 VM timings, CSS ~24× faster cold vs Rive web)
- **Wired shutter bench:** `uploads/REPORT_47fa.md` (stub capture API, Rive client-side observation delay)
- **OneInchEye camera-ui:** `camera-ui/README.md` (kiosk setup, systemd service, labwc autostart)
- **Plymouth scripting:** [freedesktop.org/wiki/Software/Plymouth/Scripts](https://www.freedesktop.org/wiki/Software/Plymouth/Scripts/)
- **Rive runtime:** [github.com/rive-app/rive-runtime](https://github.com/rive-app/rive-runtime) (C++ native player)
- **rpicam-apps:** [github.com/raspberrypi/rpicam-apps](https://github.com/raspberrypi/rpicam-apps) (`rpicam-still`)

---

*This document reflects product decisions made 2026-09-24. For implementation questions, see existing scripts in `scripts/` and `camera-ui/`.*
