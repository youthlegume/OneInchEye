# IMX283 CAMGPIO Enable Fix (CM4 pin 97 / CAM_GPIO)

## What was wrong

On Ochin CM4v2, the OneInchEye `CAM_EN` net is driven from the CM4 dedicated camera GPIO (`CameraGPIO` / `CAMGPIO`, CM4 connector pin 97).

The original `imx283-overlay.dts` only set:

- `startup-delay-us` on `&cam1_reg`

but did **not** set the regulator enable GPIO pin in the overlay.  
As a result, the camera-enable line was not being actively asserted for this board wiring, so `CAM_EN` stayed low and the sensor-side 1.8 V LDO (plus IMU rail) never came up.

## What was changed

In `imx283-overlay.dts`, under `fragment@3` (`target = <&cam1_reg>`), the following was added:

```dts
/* CM4 pin 97 (CAMGPIO / CameraGPIO) */
gpio = <&expgpio 5 0>;
regulator-always-on;
regulator-boot-on;
```

- **`gpio = <&expgpio 5 0>`** — Maps the camera regulator enable to CM4 `CAM_GPIO` (pin 97), the line routed to CAM1 FFC `CAM_EN` on Ochin CM4v2.
- **`regulator-always-on` / `regulator-boot-on`** — Ensures `cam1_reg` is enabled at boot so CAM_EN goes high and the sensor (and IMU) get power. Without these, the regulator can stay disabled and CAM_EN stays 0 V.

## Will GPIO now go high to 3.3 V?

**Yes — with the patched overlay, `cam1_reg` is enabled at boot, so CAM_EN is driven high (~3.3 V) as soon as the overlay loads.**

Why:

- `cam1_reg` is a `regulator-fixed` camera regulator in Raspberry Pi DT.
- It is defined with `enable-active-high`.
- The IMX283 node uses `VANA-supply = <&cam1_reg>`, so enabling sensor power enables `cam1_reg`.
- With `gpio = <&expgpio 5 0>`, that enable action drives `CAM_GPIO` high.

On CM4/Ochin wiring, `CAM_GPIO` is a 3.3 V logic output, so the FFC `CAM_EN` net should rise to approximately 3.3 V when enabled.

## `config.txt` lines

Use:

```ini
camera_auto_detect=0
dtoverlay=imx283
```

If using CAM0 instead of CAM1:

```ini
dtoverlay=imx283,cam0
```

Optional debug mode (forces regulator always on):

```ini
dtoverlay=imx283,always-on
```

## Install via SSH (quick steps)

From your computer, SSH into the Pi, then run:

```bash
# 1. Clone this repo on the Pi (CAMGPIO fix branch). Use cd ~ so you get ~/OneInchEye, not nested OneInchEye/OneInchEye
cd ~
git clone -b cursor/imx283-camera-enable-db1c https://github.com/youthlegume/OneInchEye.git
cd OneInchEye

# 2. Install device tree compiler and build the overlay
sudo apt update && sudo apt install -y device-tree-compiler
./apply-imx283-camgpio.sh

# 3. Backup and install the new overlay
sudo cp /boot/overlays/imx283.dtbo /boot/overlays/imx283.dtbo.bak
sudo cp build-overlay/imx283.dtbo /boot/overlays/

# 4. Enable the overlay (use nano or your preferred editor)
# On Bookworm+: use /boot/firmware/config.txt if /boot/config.txt doesn't exist
sudo nano /boot/config.txt
```

In `config.txt` add these two lines (e.g. at the end):

```
camera_auto_detect=0
dtoverlay=imx283
```

Save and exit (in nano: Ctrl+O, Enter, Ctrl+X), then reboot:

```bash
sudo reboot
```

After reboot, the CAM_EN line should go high when the camera is in use.

**If you see `env: 'bash\r': No such file or directory`:** the script had Windows line endings. On the Pi run `sed -i 's/\r$//' apply-imx283-camgpio.sh` then `./apply-imx283-camgpio.sh` again. (The repo's `.gitattributes` keeps shell scripts as LF on future clones.)

**If you ended up with nested `OneInchEye/OneInchEye`:** flatten it by moving the inner repo up:
```bash
cd ~/OneInchEye
mv OneInchEye/* .
mv OneInchEye/.git . 2>/dev/null
mv OneInchEye/.gitignore . 2>/dev/null
rmdir OneInchEye
cd ~/OneInchEye
```
Then continue from step 2. If the script gets a 404 when fetching the overlay, try `./apply-imx283-camgpio.sh rpi-6.1.y` or see the manual steps below.

If the script fails to download the overlay, see “How to apply on the Pi” below for manual steps.

---

## How to apply on the Pi (manual / if script fails)

You already have the patch in this repo (`imx283-overlay-camgpio.patch`). Use it like this:

### 1. Get the stock overlay source

The IMX283 overlay is **not** in the upstream Raspberry Pi kernel; it comes from the [imx283-v4l2-driver](https://github.com/will127534/imx283-v4l2-driver) repo. Download the unmodified overlay:

```bash
curl -sSfL -o imx283-overlay.dts "https://raw.githubusercontent.com/will127534/imx283-v4l2-driver/master/imx283-overlay.dts"
```

(Or run the script in step 2 — it fetches this file automatically.)

### 2. Apply the patch and build the overlay

**Option A — use the script (from this repo):**

```bash
cd /path/to/OneInchEye
./apply-imx283-camgpio.sh
```

This fetches the stock overlay from the driver repo, applies `imx283-overlay-camgpio.patch` (CAMGPIO + regulator-always-on), and builds `build-overlay/imx283.dtbo`.

**Option B — manual steps** (from a directory that has both the stock `imx283-overlay.dts` and the patch):

```bash
patch -p1 < /path/to/OneInchEye/imx283-overlay-camgpio.patch
dtc -@ -I dts -O dtb -o imx283.dtbo imx283-overlay.dts
```

Install the device tree compiler if needed: `sudo apt install device-tree-compiler`

### 3. Install on the Pi

On Bookworm+, overlays are loaded from `/boot/firmware/overlays/`. Install the new overlay in both places so it is used regardless of mount layout:

```bash
# Backup and install (use the path where your build produced imx283.dtbo)
sudo cp /boot/firmware/overlays/imx283.dtbo /boot/firmware/overlays/imx283.dtbo.bak
sudo cp build-overlay/imx283.dtbo /boot/firmware/overlays/

# If /boot/overlays is a different directory, update it too
sudo cp /boot/overlays/imx283.dtbo /boot/overlays/imx283.dtbo.bak 2>/dev/null || true
sudo cp build-overlay/imx283.dtbo /boot/overlays/ 2>/dev/null || true
```

### 4. Enable the overlay in config.txt

Edit `/boot/config.txt` (or `/boot/firmware/config.txt` on Bookworm+) and add:

```ini
camera_auto_detect=0
dtoverlay=imx283
```

Then reboot: `sudo reboot`.

---

## Quick verification

1. Reboot with the updated overlay.
2. Probe `CAM_EN` on the CAM1 connector.
3. Start camera use (or set `always-on`).
4. Confirm `CAM_EN` is high (~3.3 V).

