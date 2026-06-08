# OneInchEye: OpenSource IMX283 Camera Board for Raspberry Pi

![](https://imgur.com/olbFNfe.jpg)
![](https://imgur.com/RlCwAG7.jpg)

## This Fork

This repository is a fork of [Will Whang's OneInchEye](https://github.com/will127534/OneInchEye) project. The upstream design, drivers, and documentation remain the foundation; this fork extends the project toward a broader camera platform.

**Goal:** Build a family of OneInchEye-based camera variants, each tuned for a specific functional purpose (imaging style, mounting, optics, use case, etc.).

**Variant 1 — System proof-of-concept (current):** Validate that the full stack works end-to-end on real hardware. A board from the current V2.1 build is running and can produce image captures via SSH. Software integration beyond basic capture has not been started yet.

**In progress — C-mount lens testing:** A new mechanical mounting system has been designed (see [`3D/`](3D/)) to attach an actual C-mount lens and evaluate optical performance. This is the next hardware milestone for Variant 1.

| Variant | Purpose | Status |
|---------|---------|--------|
| 1 — POC | Prove the system captures images on real hardware | Capture working via SSH; optics testing next |
| 2+ | TBD — purpose-specific camera variants | Not started |

### Upstream References

- Original repo: https://github.com/will127534/OneInchEye
- Blog: https://will127534.github.io/OneInchEye/
- Quick Start Guide: https://github.com/will127534/OneInchEye/wiki/OneInchEye-Quick-Start-Guide

---

### Update on 2024/03/24
This project is also compatiable with RPI5, the quickstart guide has been updated.  

## Introduction
Welcome to the **OneInchEye** project, an open-source camera board designed for Raspberry Pi Compute Module 4 boards using the IMX283 one-inch sensor. This project aims to provide a high-quality, affordable, and accessible camera module for advanced Raspberry Pi projects. The board is designed using KiCad v6, a popular open-source electronics design automation (EDA) software.

OneInchEye captures stunning high-resolution images and videos with improved low-light performance and dynamic range. It's perfect for photography enthusiasts, developers, and makers who want to level up their Raspberry Pi projects with a powerful camera. The board also features a TMP117 temperature sensor for accurate temperature readings.

**Please note that the OneInchEye is not compatible with most Raspberry Pi boards because it requires 22-pin FPC connector with 4-lane MIPI-CSI interface. Ensure compatibility with your specific board before proceeding.**

## Features
* 1-inch IMX283 sensor
* **Open-source hardware and software**
* Integrated TMP117 temperature sensor
* Integrated 6-axis IMU ICM42688-P
* Compatible with Raspberry Pi Compute Module 4 boards with a 22-pin FPC connector and 4-lane MIPI-CSI (same pinout as Raspberry Pi Compute Module 4 IO Board)

## Support
For questions, issues, or suggestions, please open an issue in the [GitHub repository](https://github.com/will127534/OneInchEye/issues)  
Also see [Quick Start Guide](https://github.com/will127534/OneInchEye/wiki/OneInchEye-Quick-Start-Guide)


## MISC stuff  
1. Blog post(?) here: https://will127534.github.io/OneInchEye/
1. I know the decoupling capacitors in sch are a mess.....  
2. IMU is hook up at the 1.8V LDO, but that LDO is controlled by CAM_GPIO (or think as a enable pin for the camera module), so it will function only when the camera is active.
3. IMU's FSYNC is conencted to VSYNC output from the sensor for measurements/frame alignment 
4. Temperature sensor is connected to 3.3V FPC input
5. There is no clock sync function for the CMOS sensor, so the XVS and XHS are output only.  
6. QWIIC is mainly for hooking up to other I2C devices so you don't have to connect yet another cable if you add additional I2C sensor to the board. But it also serves as I2C debug port to hook up external logic analyzer.  
7. This board is actually quite easy to assemble, if you want to build board yourself, you can use JLCPCB to do the PCBA on component side and do the CMOS side with low temperature soldering paste yourself if you can source the CMOS sensor. The JLCPCB BOM and Position list is also provided.
8. Limited quantity on Tindle: https://www.tindie.com/products/will123321/oneincheye/

## License
This project is released under the MIT License.
<img width="1280" alt="image" src="https://github.com/user-attachments/assets/dd05c584-fc1a-4fa3-bc82-825419491514" />
<img width="1280" alt="image" src="https://github.com/user-attachments/assets/83b23bb7-78ab-48af-b287-addae4f33a73" />


Thanks to ChatGPT helping me generating most of the Readme, see if you can spot which section I typed.
