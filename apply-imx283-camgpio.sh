#!/usr/bin/env bash
# Apply the CAMGPIO fix patch and build imx283.dtbo.
# Run from this repo root. Requires: patch, dtc (device-tree-compiler).

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH="$REPO_ROOT/imx283-overlay-camgpio.patch"
# IMX283 overlay source is from the driver repo (not in upstream RPi kernel)
URL="https://raw.githubusercontent.com/will127534/imx283-v4l2-driver/master/imx283-overlay.dts"
WORK_DIR="${WORK_DIR:-$REPO_ROOT/build-overlay}"
DTS="$WORK_DIR/imx283-overlay.dts"
DTBO="$WORK_DIR/imx283.dtbo"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if [[ ! -f imx283-overlay.dts ]]; then
  echo "Fetching stock imx283-overlay.dts from will127534/imx283-v4l2-driver..."
  if ! curl -sSfL -o "$DTS" "$URL"; then
    echo "Failed to fetch. Get the file manually and run again:"
    echo "  curl -sSfL -o $WORK_DIR/imx283-overlay.dts $URL"
    echo "  $0"
    exit 1
  fi
fi

echo "Applying patch..."
patch -p1 < "$PATCH"

echo "Building overlay..."
dtc -@ -I dts -O dtb -o "$DTBO" "$DTS"
echo "Done. Overlay: $DTBO"
echo "On the Pi: sudo cp $DTBO /boot/firmware/overlays/  (and /boot/overlays/ if different; back up first)"
