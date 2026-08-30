#!/bin/bash
# build.sh — builds the Trio Glucose watch app and copies it to your watch
# Usage: ./build.sh <watch-model> <path-to-developer-key.der>
# Example: ./build.sh fenix7 ~/garmin-key.der

set -e

DEVICE="${1:-}"
KEY="${2:-}"

if [ -z "$DEVICE" ] || [ -z "$KEY" ]; then
  echo ""
  echo "Usage: ./build.sh <watch-model> <path-to-key.der>"
  echo ""
  echo "Common watch models:"
  echo "  fenix7    fenix7s    fenix7x"
  echo "  fenix6    fenix6s    fenix6x"
  echo "  fr955     fr945      fr265"
  echo "  vivoactive4          epix2"
  echo ""
  echo "Example: ./build.sh fenix7 ~/garmin-key.der"
  echo ""
  exit 1
fi

# Find the Connect IQ SDK
SDK_DIR=$(ls -d "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-"* 2>/dev/null | sort -V | tail -1)
if [ -z "$SDK_DIR" ]; then
  echo "ERROR: Connect IQ SDK not found."
  echo "Download it from https://developer.garmin.com/connect-iq/sdk/"
  exit 1
fi
MONKEYC="$SDK_DIR/bin/monkeyc"
echo "Using SDK: $SDK_DIR"

# Build
mkdir -p bin
echo "Building for $DEVICE..."
"$MONKEYC" \
  -f monkey.jungle \
  -o bin/TrioGlucose.prg \
  -d "$DEVICE" \
  -y "$KEY" \
  --warn

echo "Build successful: bin/TrioGlucose.prg"

# Copy to watch if it's mounted
WATCH_VOLUME=$(ls /Volumes/ | grep -iv "macintosh\|disk\|time" | head -1)
if [ -n "$WATCH_VOLUME" ] && [ -d "/Volumes/$WATCH_VOLUME/GARMIN/APPS" ]; then
  cp bin/TrioGlucose.prg "/Volumes/$WATCH_VOLUME/GARMIN/APPS/"
  echo "Copied to watch: /Volumes/$WATCH_VOLUME/GARMIN/APPS/"
  echo "Eject the watch drive in Finder, then look for Trio Glucose in your apps."
else
  echo ""
  echo "Watch not detected via USB."
  echo "Connect your watch, then drag bin/TrioGlucose.prg into GARMIN/APPS/ on the watch drive."
fi
