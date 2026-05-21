#!/bin/bash
set -e

AGENT_LABEL="com.icyscreen.agent"
AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"

echo "Removing IcyScreen..."

launchctl unload "$AGENT_PLIST" 2>/dev/null && echo "  Stopped agent." || true
rm -f "$AGENT_PLIST"                         && echo "  Removed LaunchAgent."
sudo chflags -R noschg "/Applications/IcyScreen.app" 2>/dev/null || true
sudo rm -rf "/Applications/IcyScreen.app"            && echo "  Removed app bundle."
rm -rf "$HOME/.icyscreen"                    && echo "  Removed config."
rm -f  /tmp/icyscreen.log                    && echo "  Removed log."

echo "IcyScreen fully removed."
