#!/bin/bash
# IcyScreen installer — run this once on the child's Mac.

BINARY_NAME="IcyScreenMac"
APP_BUNDLE="/Applications/IcyScreen.app"
BINARY_IN_BUNDLE="$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"
AGENT_LABEL="com.icyscreen.agent"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREBUILT="$SCRIPT_DIR/$BINARY_NAME"

# Resolve the real user even when run with sudo
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
REAL_UID=$(id -u "$REAL_USER")
AGENT_PLIST="$REAL_HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"

echo "========================================"
echo "  IcyScreen Installer"
echo "========================================"
echo ""

read -p "FTP Host        [192.168.3.21]: " FTP_HOST
FTP_HOST="${FTP_HOST:-192.168.3.21}"

read -p "FTP Username    [lyg0711]: " FTP_USER
FTP_USER="${FTP_USER:-lyg0711}"

read -s -p "FTP Password    (leave blank if none): " FTP_PASS
echo ""

read -p "FTP Remote Path [/1/KJR/mac]: " FTP_PATH
FTP_PATH="${FTP_PATH:-/1/KJR/mac}"

read -p "Capture interval in minutes [2]: " FTP_INTERVAL
FTP_INTERVAL="${FTP_INTERVAL:-2}"

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

# ── Kill any running instance before replacing the binary ─────────────────────
pkill -x "$BINARY_NAME" 2>/dev/null || true
sleep 1

# ── Install as .app bundle ─────────────────────────────────────────────────────
echo "Installing IcyScreen.app to /Applications (requires admin password)..."

sudo chflags -R nouchg,noschg "$APP_BUNDLE" 2>/dev/null || true
sudo mkdir -p "$APP_BUNDLE/Contents/MacOS"
sudo mkdir -p "$APP_BUNDLE/Contents/Resources"
sudo cp "$BINARY_SOURCE"         "$BINARY_IN_BUNDLE"
sudo cp "$SCRIPT_DIR/Info.plist" "$APP_BUNDLE/Contents/"
sudo chmod 755 "$BINARY_IN_BUNDLE"
[ -f "$SCRIPT_DIR/AppIcon.icns" ] && sudo cp "$SCRIPT_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

# Remove quarantine so macOS doesn't block execution
sudo xattr -r -d com.apple.quarantine "$APP_BUNDLE" 2>/dev/null || true

# NOTE: intentionally NOT codesigning — ad-hoc signing changes the code hash
# on every install which silently invalidates Screen Recording permission in TCC.

# Lock the bundle — prevents deletion
sudo chflags -R uchg "$APP_BUNDLE"
echo "App bundle installed."
echo ""


# ── LaunchAgent ────────────────────────────────────────────────────────────────
# Plist template is embedded here to avoid file-permission issues on Tahoe.
TMP_PLIST=$(mktemp /tmp/com.icyscreen.agent.XXXXXX.plist)
sed \
    -e "s|INSTALL_PATH_PLACEHOLDER|$BINARY_IN_BUNDLE|g" \
    -e "s|FTP_HOST_PLACEHOLDER|$FTP_HOST|g" \
    -e "s|FTP_USERNAME_PLACEHOLDER|$FTP_USER|g" \
    -e "s|FTP_PASSWORD_PLACEHOLDER|$FTP_PASS|g" \
    -e "s|FTP_PATH_PLACEHOLDER|$FTP_PATH|g" \
    -e "s|FTP_INTERVAL_PLACEHOLDER|$FTP_INTERVAL|g" \
    << 'PLIST_EOF' > "$TMP_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.icyscreen.agent</string>

    <key>ProgramArguments</key>
    <array>
        <string>INSTALL_PATH_PLACEHOLDER</string>
    </array>

    <key>EnvironmentVariables</key>
    <dict>
        <key>ICS_FTP_HOST</key>
        <string>FTP_HOST_PLACEHOLDER</string>
        <key>ICS_FTP_USERNAME</key>
        <string>FTP_USERNAME_PLACEHOLDER</string>
        <key>ICS_FTP_PASSWORD</key>
        <string>FTP_PASSWORD_PLACEHOLDER</string>
        <key>ICS_FTP_PATH</key>
        <string>FTP_PATH_PLACEHOLDER</string>
        <key>ICS_INTERVAL</key>
        <string>FTP_INTERVAL_PLACEHOLDER</string>
    </dict>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/icyscreen.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/icyscreen.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST_EOF
sudo mkdir -p "$REAL_HOME/Library/LaunchAgents"
sudo cp "$TMP_PLIST" "$AGENT_PLIST"
sudo chown "$REAL_USER" "$AGENT_PLIST"
sudo chmod 644 "$AGENT_PLIST"
rm -f "$TMP_PLIST"

launchctl asuser "$REAL_UID" launchctl unload "$AGENT_PLIST" 2>/dev/null || true
launchctl asuser "$REAL_UID" launchctl load -w "$AGENT_PLIST"

echo ""
echo "========================================"
echo "  Installation Complete"
echo "========================================"
echo ""

echo "ACTION REQUIRED — Screen Recording:"
echo "  1. Open System Settings → Privacy & Security → Screen Recording"
echo "  2. Click (+) and add /Applications/IcyScreen.app"
echo "  3. Toggle IcyScreen ON"
echo ""
echo "IcyScreen will start automatically on every login."
