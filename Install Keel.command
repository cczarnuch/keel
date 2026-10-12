#!/bin/bash
# Double-click installer. Uses macOS dialogs; you should not have to type anything.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/Library/Application Support/Steam/compatibilitytools.d/keel-proton"
STEAM="$HOME/Library/Application Support/Steam"
MACOS_DIR="$STEAM/Steam.AppBundle/Steam/Contents/MacOS"

say() {
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with title \"Keel\"" >/dev/null || true
}

mkdir -p "$(dirname "$DEST")"
# Keep the user's settings across reinstalls.
SAVED_SETTINGS=""
if [ -f "$DEST/user_settings.py" ]; then
  SAVED_SETTINGS="$(mktemp)"
  cp "$DEST/user_settings.py" "$SAVED_SETTINGS"
fi
rm -rf "$DEST"
mkdir -p "$DEST"
cp "$HERE/compatibilitytool.vdf" "$HERE/toolmanifest.vdf" "$HERE/keel" "$HERE/README.md" "$HERE/user_settings.sample.py" "$DEST/"
if [ -n "$SAVED_SETTINGS" ]; then
  mv "$SAVED_SETTINGS" "$DEST/user_settings.py"
elif [ -f "$HERE/user_settings.py" ]; then
  cp "$HERE/user_settings.py" "$DEST/user_settings.py"
else
  cp "$HERE/user_settings.sample.py" "$DEST/user_settings.py"
fi
# Steamworks bridge helper (runs inside the Wine prefix) and its source.
mkdir -p "$DEST/helpers"
cp "$HERE/helpers/keel_steam.exe" "$HERE/helpers/keel_steam.c" "$DEST/helpers/"
# Native launcher so Launch Options need no interpreter path.
if command -v clang >/dev/null 2>&1 && clang -O2 -o "$DEST/keel-launch" "$HERE/helpers/keel-launch.c"; then
  chmod +x "$DEST/keel-launch"
fi
if [ -d "$HERE/apps" ]; then
  rm -rf "$DEST/apps"
  cp -R "$HERE/apps" "$DEST/apps"
fi
chmod +x "$DEST/keel"

if [ -d "$MACOS_DIR" ]; then
  mkdir -p "$MACOS_DIR/compatibilitytools.d"
  ln -sfn "$DEST" "$MACOS_DIR/compatibilitytools.d/keel-proton"
fi

if [ -x "$DEST/keel-launch" ]; then
  LAUNCH="\"$DEST/keel-launch\" waitforexitandrun %command%"
else
  LAUNCH="/usr/bin/python3 \"$DEST/keel\" waitforexitandrun %command%"
fi
printf '%s' "$LAUNCH" | pbcopy

CHOICE="Not now"
CHOICE="$(osascript <<'APPLESCRIPT' || true
set theButton to button returned of (display dialog "Keel is installed.

Mac Steam has no Compatibility section. That page is Linux-only, and Keel cannot add it.

Quit Steam completely (Steam menu, Quit), then open it again.

A launch option is already on your clipboard. After a game is installed, open Properties and paste it into Launch Options.

Windows-only games stay hidden until Steam will download a Windows copy. Keel can turn that on. While it is on, Steam may prefer the Windows build even for games that have a Mac version. Delete the line from steam_dev.cfg to undo it." buttons {"Not now", "Enable Windows depots"} default button "Enable Windows depots" with title "Keel")
return theButton
APPLESCRIPT
)"

if [ "$CHOICE" = "Enable Windows depots" ]; then
  if [ ! -d "$MACOS_DIR" ]; then
    say "Steam for Mac is not installed yet, so the depot switch was not written. Install Steam, then run this again."
  else
    touch "$MACOS_DIR/steam_dev.cfg"
    if ! grep -q "sSteamCmdForcePlatformType" "$MACOS_DIR/steam_dev.cfg"; then
      printf '\n# Keel — delete this line to restore normal Mac Steam behavior\n@sSteamCmdForcePlatformType windows\n' >> "$MACOS_DIR/steam_dev.cfg"
    fi
  fi
fi

PY=""
if command -v python3 >/dev/null 2>&1; then
  PY="$(command -v python3)"
fi

if [ -n "$PY" ]; then
  FETCH="$(osascript <<'APPLESCRIPT' || true
set theButton to button returned of (display dialog "DirectX 11 games need DXMT, a free translator from D3D11 to Metal. Download the latest release now? It is stored in your Library folder, not inside Steam." buttons {"Skip", "Download DXMT"} default button "Download DXMT" with title "Keel")
return theButton
APPLESCRIPT
)"
  if [ "$FETCH" = "Download DXMT" ]; then
    "$PY" "$DEST/keel" fetch-dxmt || say "DXMT download failed. You can retry later with: python3 keel fetch-dxmt"
  fi
  REPORT="$("$PY" "$DEST/keel" doctor 2>&1 || true)"
  printf '%s\n' "$REPORT" > /tmp/keel-doctor.txt
  osascript <<'APPLESCRIPT' || true
set report to read POSIX file "/tmp/keel-doctor.txt"
display dialog report buttons {"OK"} default button "OK" with title "Keel doctor"
APPLESCRIPT
else
  say "Keel is installed, but Python 3 was not found. Game launches need it. Install Xcode Command Line Tools (a Mac dialog) and run this installer again."
  xcode-select --install || true
fi

exit 0
