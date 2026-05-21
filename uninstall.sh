#!/bin/bash

AGENT_LABEL="com.icyscreen.agent"
AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"

echo "Removing IcyScreen..."

launchctl unload "$AGENT_PLIST" 2>/dev/null && echo "  Stopped agent."        || true
rm -f  "$AGENT_PLIST"                       && echo "  Removed LaunchAgent."  || true
sudo chflags -R noschg "/Applications/IcyScreen.app" 2>/dev/null              || true
sudo rm -rf "/Applications/IcyScreen.app"   && echo "  Removed app bundle."   || true
rm -rf "$HOME/.icyscreen"                   && echo "  Removed config."        || true
rm -f  /tmp/icyscreen.log                   && echo "  Removed log."           || true

echo "Done."
