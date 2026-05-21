#!/bin/bash

AGENT_LABEL="com.icyscreen.agent"

# Resolve the real user's home whether run with sudo or not
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")
AGENT_PLIST="$REAL_HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"

echo "Removing IcyScreen..."

launchctl unload "$AGENT_PLIST" 2>/dev/null && echo "  Stopped agent."       || true
rm -f  "$AGENT_PLIST"                       && echo "  Removed LaunchAgent." || true
sudo chflags -R nouchg "/Applications/IcyScreen.app" 2>/dev/null             || true
sudo rm -rf "/Applications/IcyScreen.app"   && echo "  Removed app bundle."  || true
rm -f  /tmp/icyscreen.log                   && echo "  Removed log."          || true

echo "Done."
