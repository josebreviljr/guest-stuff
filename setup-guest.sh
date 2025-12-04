#!/usr/bin/env bash
set -euo pipefail

# CONFIG
BLACKBOARD_URL="https://blackboard.olemiss.edu/"
GOOGLE_LOGIN_URL="https://accounts.google.com"
GITHUB_LOGIN_URL="https://github.com/login"

BACKUP_FILE="$HOME/dock_backup.plist"

# Helpers
require_macos() {
  if [ "$(uname)" != "Darwin" ]; then
    echo "This script is for macOS only."
    exit 1
  fi
}

# Backup current Dock preferences
backup_dock() {
  if [ -f "$BACKUP_FILE" ]; then
    echo "Backup already exists at $BACKUP_FILE"
  else
    echo "Backing up current Dock configuration..."
    cp "$HOME/Library/Preferences/com.apple.dock.plist" "$BACKUP_FILE"
  fi
}

# Simplified add_app_to_dock and customize_dock functions
add_app_to_dock() {
  local app_path="$1"
  [ -d "$app_path" ] || return 0
  defaults write com.apple.dock persistent-apps -array-add "
  <dict>
    <key>tile-data</key>
    <dict>
      <key>file-data</key>
      <dict>
        <key>_CFURLString</key>
        <string>$app_path</string>
        <key>_CFURLStringType</key>
        <integer>0</integer>
      </dict>
    </dict>
    <key>tile-type</key>
    <string>file-tile</string>
  </dict>"
}

customize_dock() {
  echo "Customizing Dock..."
  defaults write com.apple.dock persistent-apps -array
  add_app_to_dock "/Applications/Firefox.app"
  add_app_to_dock "/Applications/Microsoft Word.app"
  add_app_to_dock "/Applications/Microsoft PowerPoint.app"
  add_app_to_dock "/Applications/Microsoft Excel.app"
  add_app_to_dock "/Applications/Adobe Acrobat.app"
  killall Dock >/dev/null 2>&1 || true
}

# Install Firefox if missing (same as before)
install_firefox_if_missing() {
  if [ -d "/Applications/Firefox.app" ]; then
    echo "Firefox already installed."
  else
    echo "Installing Firefox..."
    dmg="/tmp/firefox.dmg"
    curl -L "https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US" -o "$dmg"
    hdiutil attach "$dmg" -nobrowse -quiet
    volume=$(ls /Volumes | grep -i "Firefox" | head -n 1)
    cp -R "/Volumes/$volume/Firefox.app" /Applications/ 2>/dev/null || true
    hdiutil detach "/Volumes/$volume" -quiet || true
    rm -f "$dmg"
  fi
}

open_login_tabs() {
  echo "Opening login pages..."
  open -a "Firefox" "$GOOGLE_LOGIN_URL" "$BLACKBOARD_URL" "$GITHUB_LOGIN_URL"
}

main() {
  require_macos
  backup_dock
  install_firefox_if_missing
  open_login_tabs
  customize_dock
  echo "✅ Setup complete."
}

main