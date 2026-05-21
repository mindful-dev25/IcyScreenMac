#!/bin/bash
# IcyScreen installer — run this once on the child's Mac (requires admin password).
set -e

BINARY_NAME="IcyScreenMac"
INSTALL_PATH="/usr/local/bin/icyscreen"
AGENT_LABEL="com.icyscreen.agent"
AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"
TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"

echo "========================================"
echo "  IcyScreen Installer"
echo "========================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREBUILT="$SCRIPT_DIR/IcyScreenMac"

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

# ── Install binary ─────────────────────────────────────────────────────────────
echo "Installing to $INSTALL_PATH (requires admin password)..."
sudo cp "$BINARY_SOURCE" "$INSTALL_PATH"
sudo chmod 755 "$INSTALL_PATH"
sudo chown root:wheel "$INSTALL_PATH"
codesign -s - --force "$INSTALL_PATH" 2>/dev/null && echo "Binary signed." || true
echo ""

# ── Configure FTP settings (via Swift wizard) ──────────────────────────────────
"$INSTALL_PATH" --configure

# ── Screen Recording permission via TCC database ───────────────────────────────
echo "Granting Screen Recording permission..."
TCC_GRANTED=false

if [ -f "$TCC_DB" ]; then
    if sudo sqlite3 "$TCC_DB" \
        "INSERT OR REPLACE INTO access \
         (service,client,client_type,auth_value,auth_reason,auth_version,\
          csreq,policy_id,indirect_object_identifier_type,\
          indirect_object_identifier,indirect_object_code_identity,flags,last_modified) \
         VALUES ('kTCCServiceScreenCapture','$INSTALL_PATH',1,2,4,1,\
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
sed "s|INSTALL_PATH_PLACEHOLDER|$INSTALL_PATH|g" \
    "$(dirname "$0")/com.icyscreen.agent.plist" > "$AGENT_PLIST"
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
    echo "  Toggle the switch next to 'icyscreen' to ON."
    echo ""
fi

echo "  Logs:    /tmp/icyscreen.log"
echo "  Config:  $HOME/.icyscreen/config.json"
echo ""
echo "IcyScreen is running and auto-starts on every login."
