# IMX283 CAMGPIO Enable Fix (CM4 pin 97 / CAM_GPIO)

## What was wrong

On Ochin CM4v2, the OneInchEye `CAM_EN` net is driven from the CM4 dedicated camera GPIO (`CameraGPIO` / `CAMGPIO`, CM4 connector pin 97).

The original `imx283-overlay.dts` only set:

- `startup-delay-us` on `&cam1_reg`

but did **not** set the regulator enable GPIO pin in the overlay.  
As a result, the camera-enable line was not being actively asserted for this board wiring, so `CAM_EN` stayed low and the sensor-side 1.8 V LDO (plus IMU rail) never came up.

## What was changed

In `imx283-overlay.dts`, under `fragment@3` (`target = <&cam1_reg>`), this was added:

```dts
/* CM4 pin 97 (CAMGPIO / CameraGPIO) */
gpio = <&expgpio 5 0>;
```

This maps the camera regulator enable to CM4 `CAM_GPIO` (`&expgpio 5`), which is the line routed to CAM1 FFC `CAM_EN` on Ochin CM4v2.

## Will GPIO now go high to 3.3 V?

**Yes — when `cam1_reg` is enabled, this line is driven active-high.**

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
# 1. Clone this repo on the Pi (or copy the repo onto the Pi some other way)
git clone https://github.com/YOUR_USER/OneInchEye.git
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

After reboot, the CAM_EN line should go high when the camera is in use. If the script fails to download the overlay, see “How to apply on the Pi” below for manual steps.

---

## How to apply on the Pi (manual / if script fails)

You already have the patch in this repo (`imx283-overlay-camgpio.patch`). Use it like this:

### 1. Get the stock overlay source

On the Pi (or on a machine with the same kernel), get the unmodified `imx283-overlay.dts` from the Raspberry Pi kernel tree:

```bash
# Clone the kernel tree (use the branch that matches your Pi’s kernel, e.g. rpi-6.6.y)
git clone --depth 1 --branch rpi-6.6.y https://github.com/raspberrypi/linux.git rpi-linux
cp rpi-linux/arch/arm/boot/dts/overlays/imx283-overlay.dts .
```

Or download the single file from GitHub (replace `rpi-6.6.y` with your kernel branch if different):

```bash
wget -O imx283-overlay.dts "https://raw.githubusercontent.com/raspberrypi/linux/rpi-6.6.y/arch/arm/boot/dts/overlays/imx283-overlay.dts"
```

### 2. Apply the patch and build the overlay

**Option A — use the script (from this repo):**

```bash
cd /path/to/OneInchEye
./apply-imx283-camgpio.sh
```

This fetches the stock overlay (or uses an existing `build-overlay/imx283-overlay.dts`), applies `imx283-overlay-camgpio.patch`, and builds `build-overlay/imx283.dtbo`. Use `./apply-imx283-camgpio.sh rpi-5.15.y` if your Pi kernel is on an older branch.

**Option B — manual steps** (from a directory that has both the stock `imx283-overlay.dts` and the patch):

```bash
patch -p1 < /path/to/OneInchEye/imx283-overlay-camgpio.patch
dtc -@ -I dts -O dtb -o imx283.dtbo imx283-overlay.dts
```

Install the device tree compiler if needed: `sudo apt install device-tree-compiler`

### 3. Install on the Pi

```bash
# Backup the original overlay
sudo cp /boot/overlays/imx283.dtbo /boot/overlays/imx283.dtbo.bak

# Install the new overlay
sudo cp imx283.dtbo /boot/overlays/
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

