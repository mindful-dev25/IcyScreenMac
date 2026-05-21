#!/bin/bash
# Run this on your Mac to produce a shareable zip for others.
set -e

VERSION="1.0"
OUTPUT_NAME="IcyScreen-v${VERSION}"

echo "========================================"
echo "  Building IcyScreen Installer"
echo "========================================"
echo ""

# ── Build for both architectures ──────────────────────────────────────────────
echo "Building for arm64 (Apple Silicon)..."
swift build -c release --arch arm64 2>&1

echo "Building for x86_64 (Intel)..."
swift build -c release --arch x86_64 2>&1

# ── Merge into universal binary ───────────────────────────────────────────────
echo "Creating universal binary..."
lipo -create \
  ".build/arm64-apple-macosx/release/IcyScreenMac" \
  ".build/x86_64-apple-macosx/release/IcyScreenMac" \
  -output ".build/IcyScreenMac-universal"

echo "Universal binary created."
echo ""

# ── Package ───────────────────────────────────────────────────────────────────
echo "Packaging..."
rm -rf "dist/$OUTPUT_NAME"
mkdir -p "dist/$OUTPUT_NAME"

cp ".build/IcyScreenMac-universal" "dist/$OUTPUT_NAME/IcyScreenMac"
cp install.sh uninstall.sh com.icyscreen.agent.plist "dist/$OUTPUT_NAME/"
chmod +x "dist/$OUTPUT_NAME/install.sh" "dist/$OUTPUT_NAME/uninstall.sh"

cd dist/
zip -r "${OUTPUT_NAME}.zip" "${OUTPUT_NAME}/"
cd ..

echo ""
echo "========================================"
echo "  Done!"
echo "========================================"
echo ""
echo "  Shareable file:  dist/${OUTPUT_NAME}.zip"
echo ""
echo "  Instructions for recipients:"
echo "  1. Unzip the file"
echo "  2. Open Terminal, cd into the folder"
echo "  3. Run:  ./install.sh"
echo ""
