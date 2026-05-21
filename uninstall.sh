#!/bin/bash
# Run this on the child's Mac to fully remove IcyScreen.
set -e

AGENT_LABEL="com.icyscreen.agent"
AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"
INSTALL_PATH="/usr/local/bin/icyscreen"
CONFIG_DIR="$HOME/.icyscreen"

echo "Removing IcyScreen..."

launchctl unload "$AGENT_PLIST" 2>/dev/null && echo "  Stopped agent" || true
rm -f "$AGENT_PLIST"     && echo "  Removed LaunchAgent plist"
sudo rm -f "$INSTALL_PATH" && echo "  Removed binary"
rm -rf "$CONFIG_DIR"     && echo "  Removed config"
rm -f /tmp/icyscreen.log && echo "  Removed log"

echo "IcyScreen fully removed."
