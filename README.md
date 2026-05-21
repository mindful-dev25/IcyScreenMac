# IcyScreenMac

A silent macOS screenshot monitor that uploads to FTP. Runs invisibly, auto-starts, and resists removal.

## Requirements

- macOS 14 (Sonoma) or later
- Intel or Apple Silicon Mac

## Install

```bash
unzip IcyScreen-v1.0.zip
cd IcyScreen-v1.0
./install.sh
```

The installer will prompt for:
- FTP server IP / hostname
- FTP username & password
- Remote folder path
- Capture interval (minutes)
- Screenshot filename format

## Behavior

- Runs silently — no Dock icon, no window
- Auto-starts on every login
- Restarts within 10 seconds if force-quit
- Locked in `/Applications` — drag to Trash is blocked

## Change Settings

```bash
/Applications/IcyScreen.app/Contents/MacOS/IcyScreenMac --configure
```

## Uninstall

```bash
./uninstall.sh
```

## Build from Source

Requires Xcode Command Line Tools (`xcode-select --install`).

```bash
# Run the app
swift build -c release

# Create shareable installer zip
./make_installer.sh
```
