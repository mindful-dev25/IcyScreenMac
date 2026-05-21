#!/bin/bash
# IcyScreen installer — run this once on the child's Mac (requires admin password).
set -e

BINARY_NAME="IcyScreenMac"
APP_BUNDLE="/Applications/IcyScreen.app"
BINARY_IN_BUNDLE="$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"
AGENT_LABEL="com.icyscreen.agent"
AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"
TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREBUILT="$SCRIPT_DIR/$BINARY_NAME"

echo "========================================"
echo "  IcyScreen Installer"
echo "========================================"
echo ""

# ── Build or use pre-built binary ─────────────────────────────────────────────
if [ -f "$PREBUILT" ]; then
    echo "Using pre-built binary."
    echo ""
    BINARY_SOURCE="$PREBUILT"
else
    if ! command -v swift &>/dev/null; then
        echo "ERROR: No pre-built binary found and Swift is not installed."
        echo "Install Xcode Command Line Tools:  xcode-select --install"
        exit 1
    fi
    echo "Building from source..."
    swift build -c release 2>&1
    BUILD_OUTPUT=".build/release/$BINARY_NAME"
    if [ ! -f "$BUILD_OUTPUT" ]; then
        echo "ERROR: Build failed."
        exit 1
    fi
    echo "Build succeeded."
    echo ""
    BINARY_SOURCE="$BUILD_OUTPUT"
fi

# ── Install as .app bundle ─────────────────────────────────────────────────────
echo "Installing IcyScreen.app to /Applications (requires admin password)..."

# Unlock first in case a previous install locked the bundle
sudo chflags -R noschg "$APP_BUNDLE" 2>/dev/null || true

sudo mkdir -p "$APP_BUNDLE/Contents/MacOS"
sudo mkdir -p "$APP_BUNDLE/Contents/Resources"
sudo cp "$BINARY_SOURCE"                    "$BINARY_IN_BUNDLE"
sudo cp "$SCRIPT_DIR/Info.plist"            "$APP_BUNDLE/Contents/"
sudo chmod 755 "$BINARY_IN_BUNDLE"
[ -f "$SCRIPT_DIR/AppIcon.icns" ] && sudo cp "$SCRIPT_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

# Ad-hoc sign the bundle so TCC tracks it by bundle ID
codesign -s - --force "$APP_BUNDLE" 2>/dev/null && echo "App bundle signed." || true

# Lock the bundle — prevents deletion even by admins (drag to Trash will fail)
sudo chflags -R schg "$APP_BUNDLE"
echo "App bundle locked (deletion protected)."
echo ""

# ── Configure FTP settings ─────────────────────────────────────────────────────
"$BINARY_IN_BUNDLE" --configure

# ── Screen Recording permission via TCC database ───────────────────────────────
echo "Granting Screen Recording permission..."
TCC_GRANTED=false
BUNDLE_ID="com.icyscreen.agent"

if [ -f "$TCC_DB" ]; then
    if sudo sqlite3 "$TCC_DB" \
        "INSERT OR REPLACE INTO access \
         (service,client,client_type,auth_value,auth_reason,auth_version,\
          csreq,policy_id,indirect_object_identifier_type,\
          indirect_object_identifier,indirect_object_code_identity,flags,last_modified) \
         VALUES ('kTCCServiceScreenCapture','$BUNDLE_ID',0,2,4,1,\
                 NULL,NULL,0,'UNUSED',NULL,0,\
                 CAST(strftime('%s','now') AS INTEGER));" 2>/dev/null; then
        sudo pkill -9 tccd 2>/dev/null || true
        sleep 1
        echo "Screen Recording permission granted automatically."
        TCC_GRANTED=true
    else
        echo "TCC database write blocked (normal on macOS 14+)."
    fi
fi

# ── LaunchAgent ────────────────────────────────────────────────────────────────
mkdir -p "$HOME/Library/LaunchAgents"
sed "s|INSTALL_PATH_PLACEHOLDER|$BINARY_IN_BUNDLE|g" \
    "$SCRIPT_DIR/com.icyscreen.agent.plist" > "$AGENT_PLIST"
launchctl unload "$AGENT_PLIST" 2>/dev/null || true
launchctl load -w "$AGENT_PLIST"

echo ""
echo "========================================"
echo "  Installation Complete"
echo "========================================"
echo ""

if [ "$TCC_GRANTED" = false ]; then
    echo "ACTION REQUIRED — Screen Recording:"
    echo "  System Settings will open automatically."
    echo "  Find 'IcyScreen' in the list and toggle it ON."
    echo ""
fi

echo "IcyScreen is running and auto-starts on every login."
