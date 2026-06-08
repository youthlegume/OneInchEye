# Mechanical Design

3D models for integrating the OneInchEye camera board with lenses and mounts. Designed in Fusion 360; exported here as STEP/STL for reference and fabrication.

## Board Mechanical Reference

The V2.1 PCB is a **39 × 39 mm** square with **4× M2 mounting holes** (2.5 mm inset from each edge, 34 mm hole-to-hole). A ~4 × 4 mm center cutout clears the sensor stack. Use `OneInchEye.step` (KiCad assembly export) for exact component placement and board thickness (1.6 mm, 4-layer).

## Files

| File | Description |
|------|-------------|
| `OneInchEye.step` | Full PCB assembly with components — reference for mechanical fit |
| `IMX283.step` | IMX283 sensor 3D model (Fusion 360) |
| `PassiveEmount.stl` | Passive Sony E-mount lens adapter |
| `QuickReleaseMount.stl` | Quick-release mounting bracket |

## Current Work — C-Mount Lens Testing

A new mounting system is being designed and tested to attach a **C-mount lens** to the camera board. This is the next hardware step for Variant 1 (system proof-of-concept): validate that real optics produce usable images before moving on to purpose-built camera variants.

Mount designs should account for:

- Sensor centering over the PCB cutout
- Flange focal distance for the chosen mount standard (C-mount: 17.526 mm)
- Clearance for the IMX283 package height and any IR filter stack
- Alignment with the 4× M2 board mounting pattern

## Variant Roadmap (Mechanical)

Each camera variant may need its own mount, enclosure, or optical interface. Variant 1 focuses on a functional C-mount test rig; later variants will define mechanical requirements per use case.
