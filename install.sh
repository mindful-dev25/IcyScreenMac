#!/bin/bash
# IcyScreen installer — run this once on the child's Mac (requires admin password).
set -e

BINARY_NAME="IcyScreenMac"
INSTALL_PATH="/usr/local/bin/icyscreen"
AGENT_LABEL="com.icyscreen.agent"
AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"
CONFIG_DIR="$HOME/.icyscreen"
CONFIG_FILE="$CONFIG_DIR/config.json"

echo "========================================"
echo "  IcyScreen Installer"
echo "========================================"
echo ""

# ── Prerequisites ──────────────────────────────────────────────────────────────
if ! command -v swift &>/dev/null; then
    echo "ERROR: Swift not found."
    echo "Install Xcode Command Line Tools first:"
    echo "  xcode-select --install"
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
# Remove write permission so a standard user cannot replace it
sudo chown root:wheel "$INSTALL_PATH"
echo "Binary installed."
echo ""

# ── FTP configuration ──────────────────────────────────────────────────────────
mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "========================================"
    echo "  FTP Server Configuration"
    echo "========================================"
    read -r -p "FTP server IP or hostname:     " FTP_HOST
    read -r -p "FTP username:                  " FTP_USER
    read -r -s -p "FTP password:                  " FTP_PASS
    echo ""
    read -r -p "Remote folder path [/screenshots]: " FTP_PATH
    FTP_PATH="${FTP_PATH:-/screenshots}"
    read -r -p "Capture interval in minutes [2]:   " INTERVAL
    INTERVAL="${INTERVAL:-2}"

    # Validate interval is a number
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
    # Restrict config to current user only
    chmod 600 "$CONFIG_FILE"
    echo ""
    echo "Config saved to $CONFIG_FILE"
fi

# ── LaunchAgent ────────────────────────────────────────────────────────────────
mkdir -p "$HOME/Library/LaunchAgents"

sed "s|INSTALL_PATH_PLACEHOLDER|$INSTALL_PATH|g" \
    "$(dirname "$0")/com.icyscreen.agent.plist" > "$AGENT_PLIST"

# Reload (unload first in case it was already loaded)
launchctl unload "$AGENT_PLIST" 2>/dev/null || true
launchctl load -w "$AGENT_PLIST"

echo ""
echo "========================================"
echo "  Installation Complete"
echo "========================================"
echo ""
echo "IMPORTANT — Screen Recording permission required:"
echo ""
echo "  1. Open:  System Settings > Privacy & Security > Screen Recording"
echo "  2. Click the (+) button"
echo "  3. Navigate to /usr/local/bin/ and add 'icyscreen'"
echo "  4. Enable the toggle next to 'icyscreen'"
echo ""
echo "After granting permission the agent will restart automatically"
echo "and begin capturing every $INTERVAL minute(s)."
echo ""
echo "  Logs:    /tmp/icyscreen.log"
echo "  Config:  $CONFIG_FILE"
echo ""
echo "IcyScreen is now running and will restart automatically on every login."
echo "If the process is force-quit, launchd will restart it within 10 seconds."
