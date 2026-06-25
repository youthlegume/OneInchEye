ufg# One-Inch Eye Camera: Build Guide

A simple step-by-step guide to build a **One-Inch Eye** camera using a **Raspberry Pi Compute Module 4 (CM4)**, the **Seeed ochin CM4v2 carrier board**, and the **OneInchEye** camera board. This guide covers both hardware assembly and software setup in plain English.

---

## What You’re Building

You’ll end up with a compact camera system that uses:

- **Raspberry Pi CM4** – the brain (with eMMC storage).
- **Seeed ochin CM4v2** – small carrier board that gives you power, USB, CSI camera ports, and a USB-C port for flashing.
- **OneInchEye** – open-source camera board with a 1-inch IMX283 sensor (better image quality and low-light than typical Pi cameras).

The OneInchEye needs a **22-pin FPC connector with 4-lane MIPI-CSI** (same as the Raspberry Pi CM4 IO Board CAM1 port). The ochin carrier has two CSI camera connectors that match this.

---

## What You Need

### Hardware

| Item | Notes |
|------|--------|
| **Raspberry Pi CM4** | With eMMC (e.g. 8GB–32GB). 1GB–8GB RAM is fine; 2GB+ is comfortable. |
| **Seeed ochin CM4v2** | Carrier board. Buy from [Seeed Studio](https://www.seeedstudio.com) or partners (Digi-Key, Mouser, etc.). |
| **OneInchEye camera board** | With IMX283 sensor. Assemble from this repo’s design or buy a pre-built unit (e.g. [Tindie](https://www.tindie.com/products/will123321/oneincheye/)). |
| **22-pin FPC cable** | To connect OneInchEye to one of the ochin’s CSI ports. Match length and orientation to your layout. |
| **Power supply** | 5 V, suitable current for CM4 + camera (e.g. 2.5–3 A). Check ochin manual for connector. |
| **USB-C cable** | For flashing the CM4 eMMC (plug into the ochin’s “flashing” USB-C port). |
| **Optional** | CM4 extractor tool (recommended): [ochin 3D extractor](https://github.com/ochin-space/ochin-CM4v2/tree/master/3d/CoversTurretsAndExtractors) so you don’t damage the board when removing the CM4. |

### Software (on your computer, for flashing)

- **Raspberry Pi Imager** or another way to write an OS image.
- **rpiboot** (for CM4 with eMMC): so your PC can see the CM4’s eMMC as a disk when the board is in USB boot mode.

### References (open before you start)

- **ochin CM4v2 repo**: [github.com/ochin-space/ochin-CM4v2](https://github.com/ochin-space/ochin-CM4v2)  
  - Read the **manual** and **öchìnCM4v2-WiringAndSuggestions.pdf** before powering the board.
  - **öchìnCM4v2-HW-bugs.pdf** lists known hardware issues and fixes.
- **OneInchEye repo**: [github.com/will127534/OneInchEye](https://github.com/will127534/OneInchEye)  
  - [Wiki: OneInchEye Quick Start Guide](https://github.com/will127534/OneInchEye/wiki/OneInchEye-Quick-Start-Guide) for software.

**Important (from ochin docs):** Do **not** rely on FPC/cable wire colors. Connector pin order on the ochin is fixed; always follow the wiring/suggestions PDF for which pin is which.

---

## Part 1: Hardware Assembly

### Step 1: Get the CM4 ready (and use the extractor when handling it)

- If you have the **ochin CM4 extractor** (STL in the ochin repo), print it and use it whenever you install or remove the CM4 so you don’t bend or break the connector.
- Keep the CM4 in antistatic packaging until you’re ready to install it.

### Step 2: Install the CM4 on the ochin carrier

- Place the ochin board on a clean, static-safe surface.
- Align the CM4 with the board’s connector: match the keying and pin one. Don’t force it.
- Press the CM4 down evenly until it is fully seated. If you have the extractor, use it as intended for insertion/removal.
- Double-check that the module is flat and fully inserted.

### Step 3: Connect the OneInchEye to the ochin (CSI)

- The ochin has **two** CSI camera connectors (22-pin, same style as CM4 IO Board CAM1).
- Use **one** of them for the OneInchEye (e.g. the first CSI port; if the manual labels them CAM0/CAM1, use the one that corresponds to the primary camera).
- **FPC connection:**
  - Use a **22-pin FPC cable**.
  - Follow the [OneInchEye FPC connection guide](https://github.com/will127534/OneInchEye/wiki/How-to-connect-the-FPC-connector).
  - Align the FPC with the connector so that pin 1 matches (see below). Connector orientation matters.
  - Seat the FPC fully and close the connector latch gently so the cable is held firmly.
- **Finding pin 1 (your cable has no pin markings):** MIPI/FFC ribbon cables usually have **no pin order printed on them**—only ratings like 80°C, 60V, AWM, VW-1. To get orientation right, use the **boards**, not the cable:
  - **On the PCB:** Pin 1 is almost always marked next to the connector—look for a small triangle, dot, “1”, or “▼” on the silkscreen. The first conductor on the cable should align with that pin.
  - **OneInchEye:** Pin 1 on the OneInchEye FPC connector is **+3.3 V** and is at **one end** of the 22-pin row. Look on the board next to the FPC connector for a silkscreen mark (small **"1"**, triangle **▼**, or dot) at the pin-1 end; the first conductor (one edge) of the ribbon must align with that end. If there is no mark, the end of the connector that connects to 3.3 V on the board is pin 1. See the [OneInchEye FPC connection guide](https://github.com/will127534/OneInchEye/wiki/How-to-connect-the-FPC-connector) and any assembly photos in the repo.
  - **ochin carrier:** Use the **öchìnCM4v2-WiringAndSuggestions.pdf** (and manual) for the CSI connector pinout and pin-1 position so you plug the cable in the right way on the ochin side.
- Do **not** trust wire or cable colors to indicate pin order: use the connector pinout in the ochin wiring PDF.

### Step 4: Don’t power up yet

- Do **not** connect power until you’ve read the ochin wiring PDF and confirmed that any other connections (power, USB, etc.) are correct.
- If you have other peripherals (USB, UART, etc.), connect them according to the manual and wiring guide.

### Step 5: First power-on (do this after Part 2)

- **Complete Part 2 (Software – Flashing the CM4) first.** Only then connect the main power supply.
- Connect the 5 V power supply to the ochin as specified in its manual and power on. The board will boot from the eMMC.

---

## Part 2: Software – Flashing the CM4 (eMMC)

The ochin has a **USB Type-C port for flashing** the CM4’s eMMC. You put the CM4 into “USB boot” mode so your computer sees the eMMC as a disk, then write the OS image.

### Step 1: Put the CM4 in USB boot mode

- With the board **unpowered**, you need to make the CM4 expose its eMMC over USB when you plug in the USB-C cable.
- On the **ochin**, this is usually done by:
  - Setting a jumper or switch to “eMMC flash” / “USB boot” (if the board has one), **or**
  - Holding a “BOOT” or “nRPIBOOT” button (if present) while connecting the USB-C cable to your PC.
- Check the **ochin manual** and **Quick Start Flashing Guide** in the [ochin-CM4v2 repo](https://github.com/ochin-space/ochin-CM4v2) for the exact steps and any diagrams.

### Step 2: Install rpiboot on your computer (Windows / Mac / Linux)

- Install **rpiboot** so your PC can talk to the CM4 in USB boot mode:
  - [Raspberry Pi rpiboot](https://github.com/raspberrypi/usbboot)
- **Mac:** You can use the script in this repo: `bash scripts/install-rpiboot.sh` (see script comments for Homebrew permissions if needed). It installs into Homebrew’s prefix so the default boot-file path works.
- Other OS: follow the usbboot repo’s instructions.

### Step 3: Connect and run rpiboot

- Connect the ochin’s **flashing USB-C port** to your computer (with the board in USB boot mode as in Step 1).
- Run rpiboot:
  - **If you used our Mac script:** run `sudo rpiboot`.
  - **If you see “Failed to read” and “trying default /usr/local/...”** (e.g. you built with `/usr/local` but that path doesn’t exist on your Mac), specify the boot-files directory instead:
    - Installed via Homebrew prefix:  
      `sudo rpiboot -d /opt/homebrew/share/rpiboot/mass-storage-gadget64`
    - Or from this repo’s clone (from the project root):  
      `cd rpiboot-tools/mass-storage-gadget64 && ./reset.sh && cd .. && sudo ./rpiboot -d mass-storage-gadget64`
- The CM4’s eMMC should appear as a removable drive on your computer.
- **macOS “disk not readable”:** If macOS says “The disk you attached was not readable by this computer,” that’s normal for a blank or Linux-formatted eMMC. Click **Ignore** (or Eject), then use **Raspberry Pi Imager** in Step 4 to write the image; Imager writes to the disk directly and does not need the volume to be readable.

### Step 4: Write Raspberry Pi OS to the eMMC

- Use **Raspberry Pi Imager** (or similar):
  - Choose **Raspberry Pi OS (64-bit)**.
  - Select the **eMMC drive** that appeared (be very careful to pick the right disk).
  - Optionally set hostname, user, SSH, Wi-Fi, etc.
  - Write the image.
- Or: use `dd` / `balenaEtcher` to write an official Raspberry Pi OS image to that drive.
- When finished, safely eject the drive, disconnect USB-C, and (if you had one) remove the boot jumper or release the boot button.

### Step 5: Boot from eMMC

- Disconnect the USB-C flashing cable.
- Connect the **power supply** to the ochin and power on. The CM4 should boot from eMMC into Raspberry Pi OS.

---

## Part 3: Software – OneInchEye Camera Setup (on the Pi)

Once the Pi has booted (over SSH or with keyboard/monitor), follow the **OneInchEye Quick Start Guide** to make the IMX283 sensor work. Summary below; always check the [wiki](https://github.com/will127534/OneInchEye/wiki/OneInchEye-Quick-Start-Guide) for your OS/kernel version.

### Step 1: Update the system

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Build and install libcamera (IMX283 support)

Install dependencies:

```bash
sudo apt install -y libboost-dev libgnutls28-dev openssl libtiff5-dev pybind11-dev qtbase5-dev libqt5core5a libqt5gui5 libqt5widgets5 meson cmake python3-yaml python3-ply
```

Build and install the fork of libcamera that supports the IMX283:

```bash
cd ~
git clone https://github.com/will127534/libcamera.git
cd libcamera
meson setup build --buildtype=release -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp -Dv4l2=enabled -Dgstreamer=disabled -Dtest=false -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled -Dpycamera=enabled -Dwrap_mode=forcefallback
ninja -C build
sudo ninja -C build install
```

### Step 3: Build and install libcamera-apps

Install dependencies (required before `meson setup`; libav* for video encoding, libexif for EXIF in images). Run the full line so all are present:

```bash
sudo apt update
sudo apt install -y cmake libboost-program-options-dev libdrm-dev libexif-dev libepoxy-dev libjpeg-dev libtiff5-dev libpng-dev meson ninja-build libavcodec-dev libavdevice-dev libavformat-dev libswresample-dev
```

If `libavcodec-dev` is not found, use the Lite meson options with `-Denable_libav=disabled` below. If meson reports another missing dependency (e.g. `libexif`), install it (e.g. `sudo apt install -y libexif-dev`) and run `rm -rf build` then `meson setup build ...` again.

Clone and enter rpicam-apps:

```bash
cd ~
git clone https://github.com/will127534/rpicam-apps.git
cd rpicam-apps
```

**Important:** The `meson setup` commands below are for **rpicam-apps** only. Run them from the `~/rpicam-apps` directory (not from `~/libcamera`). If a previous `meson setup` failed, remove the build dir first: `rm -rf build`.

For full Raspberry Pi OS (with desktop):

```bash
meson setup build -Denable_libav=enabled -Denable_drm=enabled -Denable_egl=enabled -Denable_qt=enabled -Denable_opencv=disabled -Denable_tflite=disabled
```

For Raspberry Pi OS Lite (or if libavcodec is not available):

```bash
meson setup build -Denable_libav=disabled -Denable_drm=enabled -Denable_egl=disabled -Denable_qt=disabled -Denable_opencv=disabled -Denable_tflite=disabled
```

Then:

```bash
meson compile -C build
sudo meson install -C build
sudo ldconfig
```

### Step 4: Install the IMX283 kernel driver (DKMS)

Install tools (on Trixie or newer you may not need `linux-headers`; on older releases you do):

```bash
sudo apt install -y dkms git
# On Raspberry Pi OS before Trixie (before Oct 2025):
# sudo apt install -y linux-headers dkms git
```

Choose the driver branch that matches your kernel (check with `uname -r`):

- Kernel **6.12** (e.g. Trixie and later): use branch `6.12.y`
- Kernel **6.6**: use branch `6.6.y`
- Kernel **6.1**: use branch `6.1.y`

Example for 6.12:

```bash
git clone https://github.com/will127534/imx283-v4l2-driver.git --branch 6.12.y
cd imx283-v4l2-driver/
sudo ./setup.sh
```

### Step 5: Configure the boot config for the camera

Edit the boot config:

```bash
sudo nano /boot/firmware/config.txt
```

- Set `camera_auto_detect=0`
- Add the IMX283 overlay:
  - **Camera on first CSI port (CAM0):** `dtoverlay=imx283,cam0`
  - **Camera on second CSI port (CAM1):** `dtoverlay=imx283`

So you have (example for CAM0):

```
camera_auto_detect=0
dtoverlay=imx283,cam0
```

Save and exit (e.g. Ctrl+O, Enter, Ctrl+X in nano).

### Step 6: Reboot

```bash
sudo reboot
```

### Step 7: Test the camera

After reboot:

```bash
rpicam-still -r -o test.jpg -f -t 0
```

If you’re on SSH and want the preview on an HDMI display:

```bash
export DISPLAY=:0; rpicam-still -r -o test.jpg -f -t 0
```

For CAM0 vs CAM1: if the camera is on the first CSI port (CAM0), use `--camera 0`; for the second port (CAM1), use `--camera 1`. Example for CAM0: `rpicam-still --camera 0 -r -o test.jpg -f -t 0`.

If you see a captured image and no errors, the OneInchEye is working.

### Optional: Picamera2 (Python)

If you use Picamera2, the OneInchEye wiki describes compatible versions and a `local.pth` setup for the libcamera fork. See the [Quick Start Guide](https://github.com/will127534/OneInchEye/wiki/OneInchEye-Quick-Start-Guide) “Picamera2” section.

### Optional: Camera web UI + kiosk boot

A web interface for camera control lives in **camera-ui/** (port 3000). For **power-on → fullscreen camera UI** (no browser chrome) on the 480×480 display:

1. SSH in with the display unplugged.
2. Run `bash scripts/setup-camera-kiosk.sh` from the repo root (see **camera-ui/README.md**).
3. Reboot with the display connected.

The script enables desktop autologin, starts the UI via systemd, and launches Chromium in kiosk mode via labwc autostart.

---

## Troubleshooting

- **“rpicam-apps only supports the raspberry pi platform”**  
  Usually means the IMX283 driver isn’t loaded. Check:
  - `dmesg | grep imx283` – you should see messages about the sensor being found.
  - `config.txt`: `camera_auto_detect=0` and `dtoverlay=imx283`.
  - Re-run the driver `setup.sh` if needed and reboot.

- **Kernel headers not found when building the driver**  
  On non-standard kernels you may need [rpi-source](https://github.com/RPi-Distro/rpi-source) to get matching headers; see the OneInchEye wiki.

- **dmesg: "probe with driver imx283 failed with error -5" or "Error reading reg 0x3000"** — Overlay defaults to CAM1. If the cable is on the first CSI port (CAM0), use `dtoverlay=imx283,cam0` in config.txt and reboot.

- **"Could not open any dmaHeap device"**  
  (1) Give the video group access: create `/etc/udev/rules.d/raspberrypi.rules` with:
  ```
  SUBSYSTEM=="dma_heap", GROUP="video", MODE="0660"
  ```
  (2) On kernel 6.x the CMA heap is named `reserved`, but libcamera looks for `linux,cma` first. If `ls /dev/dma_heap/` shows `reserved` and `system` but no `linux,cma`, add a symlink so libcamera finds it. One-time: `sudo ln -sf reserved /dev/dma_heap/linux,cma`. To make it persistent, add a second line to the same udev file:
  ```
  SUBSYSTEM=="dma_heap", KERNEL=="reserved", SYMLINK+="dma_heap/linux,cma"
  ```
  Reboot, then run `rpicam-still -o test.jpg` as your normal user.

- **"dmaHeap allocation failure" / "failed to allocate capture buffers"**  
  If you also see "Could not open any dmaHeap device", fix that first (udev rule above). Otherwise the system may not have enough contiguous memory: add `cma=256M` (or `cma=384M` if needed) to the end of `/boot/firmware/cmdline.txt`, then reboot.

- **No picture / camera not detected**  
  - Check FPC connection (pin 1, orientation, latch closed).
  - Confirm you’re using the correct CSI port and that the ochin manual’s pin order matches your cable (don’t rely on wire color).
  - Re-check **öchìnCM4v2-WiringAndSuggestions.pdf**.

- **Flashing / USB boot**  
  - Follow the ochin manual and Quick Start Flashing Guide exactly (jumper, button, USB-C port).
  - Ensure you’re using the **flashing** USB-C port on the ochin, not a normal data port.

---

## Quick Reference Links

| Resource | Link |
|----------|------|
| OneInchEye project | [github.com/will127534/OneInchEye](https://github.com/will127534/OneInchEye) |
| OneInchEye Quick Start (software) | [Wiki: OneInchEye-Quick-Start-Guide](https://github.com/will127534/OneInchEye/wiki/OneInchEye-Quick-Start-Guide) |
| OneInchEye FPC connection | [Wiki: How-to-connect-the-FPC-connector](https://github.com/will127534/OneInchEye/wiki/How-to-connect-the-FPC-connector) |
| Seeed ochin CM4v2 repo | [github.com/ochin-space/ochin-CM4v2](https://github.com/ochin-space/ochin-CM4v2) |
| ochin manual / wiring / HW bugs | In ochin-CM4v2: Manual PDF, WiringAndSuggestions.pdf, HW-bugs.pdf |
| CM4 rpiboot (flashing) | [github.com/raspberrypi/usbboot](https://github.com/raspberrypi/usbboot) |
| Raspberry Pi Imager | [raspberrypi.com/software](https://www.raspberrypi.com/software/) |

---

*This guide is for the OneInchEye + Raspberry Pi CM4 + Seeed ochin CM4v2. For other carriers or CM4 IO Board, hardware steps differ slightly; software steps remain the same. Always read the ochin manual and wiring guide before first power-on.*
