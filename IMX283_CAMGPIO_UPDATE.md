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

## Quick verification

1. Reboot with the updated overlay.
2. Probe `CAM_EN` on the CAM1 connector.
3. Start camera use (or set `always-on`).
4. Confirm `CAM_EN` is high (~3.3 V).

