#!/bin/bash
# Generates AppIcon.icns — run once, or whenever you want a new icon.
set -e

echo "Generating AppIcon.icns..."

# ── Draw 1024x1024 PNG with Swift ─────────────────────────────────────────────
swift - << 'SWIFT'
import AppKit

let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// Blue rounded-rect background
let bg = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
                      xRadius: 200, yRadius: 200)
NSGradient(starting: NSColor(red: 0.20, green: 0.52, blue: 0.95, alpha: 1),
           ending:   NSColor(red: 0.10, green: 0.32, blue: 0.75, alpha: 1))?
    .draw(in: bg, angle: -80)

// Camera body
NSColor.white.withAlphaComponent(0.95).setFill()
NSBezierPath(roundedRect: NSRect(x: 212, y: 330, width: 600, height: 380),
             xRadius: 60, yRadius: 60).fill()

// Viewfinder bump
NSBezierPath(roundedRect: NSRect(x: 390, y: 670, width: 160, height: 70),
             xRadius: 30, yRadius: 30).fill()

// Lens outer ring
NSColor(red: 0.12, green: 0.38, blue: 0.78, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 337, y: 370, width: 350, height: 350)).fill()

// Lens inner (white)
NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(x: 387, y: 420, width: 250, height: 250)).fill()

// Lens centre (blue)
NSColor(red: 0.12, green: 0.38, blue: 0.78, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 437, y: 470, width: 150, height: 150)).fill()

// Shine dot
NSColor.white.withAlphaComponent(0.6).setFill()
NSBezierPath(ovalIn: NSRect(x: 467, y: 540, width: 55, height: 55)).fill()

image.unlockFocus()

let tiff   = image.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: tiff)!
let png    = bitmap.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "icon_1024.png"))
print("Base PNG created.")
SWIFT

# ── Build iconset with all required sizes ─────────────────────────────────────
mkdir -p AppIcon.iconset

for size in 16 32 64 128 256 512 1024; do
    sips -z $size $size icon_1024.png --out "AppIcon.iconset/icon_${size}x${size}.png" &>/dev/null
done

# @2x variants
cp AppIcon.iconset/icon_32x32.png   AppIcon.iconset/icon_16x16@2x.png
cp AppIcon.iconset/icon_64x64.png   AppIcon.iconset/icon_32x32@2x.png
cp AppIcon.iconset/icon_256x256.png AppIcon.iconset/icon_128x128@2x.png
cp AppIcon.iconset/icon_512x512.png AppIcon.iconset/icon_256x256@2x.png
cp AppIcon.iconset/icon_1024x1024.png AppIcon.iconset/icon_512x512@2x.png

# ── Convert to .icns ──────────────────────────────────────────────────────────
iconutil -c icns AppIcon.iconset -o AppIcon.icns

# Cleanup
rm -rf AppIcon.iconset icon_1024.png

echo "AppIcon.icns created."
