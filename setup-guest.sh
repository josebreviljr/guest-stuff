#!/usr/bin/env bash
set -euo pipefail

########################################
# CONFIG – EDIT THESE FOR YOUR SCHOOL
########################################

# TODO: set this to your real Blackboard login URL
BLACKBOARD_URL="https://your-school.blackboard.com"

GOOGLE_LOGIN_URL="https://accounts.google.com"
GITHUB_LOGIN_URL="https://github.com/login"

# Where to store backups for this user
BACKUP_DIR="${HOME}/.guest_env_backup"
DOCK_BACKUP="${BACKUP_DIR}/dock.plist"

########################################
# HELPERS
########################################

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_macos() {
  if [ "$(uname)" != "Darwin" ]; then
    echo "This script is intended for macOS only."
    exit 1
  fi
}

########################################
# FIREFOX – INSTALL IF NEEDED
########################################

install_firefox_dmg() {
  echo "Attempting to install Firefox via DMG..."
  local dmg="/tmp/firefox.dmg"

  curl -L "https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US" -o "$dmg"

  echo "Mounting Firefox DMG..."
  hdiutil attach "$dmg" -nobrowse -quiet

  # Find the Firefox volume
  local volume
  volume=$(ls /Volumes | grep -i "Firefox" | head -n 1 || true)

  if [ -z "$volume" ]; then
    echo "Could not find Firefox volume. Aborting Firefox install."
    hdiutil detach "/Volumes/Firefox" >/dev/null 2>&1 || true
    rm -f "$dmg"
    return 1
  fi

  local src="/Volumes/$volume/Firefox.app"
  local dst="/Applications/Firefox.app"

  if [ ! -d "$src" ]; then
    echo "Firefox.app not found on mounted volume. Aborting."
    hdiutil detach "/Volumes/$volume" >/dev/null 2>&1 || true
    rm -f "$dmg"
    return 1
  fi

  echo "Copying Firefox to /Applications (may require password)..."
  if cp -R "$src" "$dst" 2>/dev/null; then
    echo "Firefox installed successfully."
  else
    echo "Could not copy to /Applications (no permission)."
    echo "Try running this script with sudo or install Firefox manually."
  fi

  echo "Detaching DMG..."
  hdiutil detach "/Volumes/$volume" -quiet || true
  rm -f "$dmg"
}

ensure_firefox() {
  if [ -d "/Applications/Firefox.app" ]; then
    echo "Firefox already installed."
  else
    echo "Firefox not found in /Applications."
    install_firefox_dmg || echo "Firefox installation failed or incomplete."
  fi
}

########################################
# DOCK BACKUP / RESTORE
########################################

backup_dock() {
  echo "Backing up current Dock configuration to: $DOCK_BACKUP"
  mkdir -p "$BACKUP_DIR"
  # Export current Dock plist as XML
  if defaults export com.apple.dock - > "$DOCK_BACKUP" 2>/dev/null; then
    echo "Dock backup complete."
  else
    echo "Warning: failed to backup Dock settings."
  fi
}

restore_dock() {
  if [ ! -f "$DOCK_BACKUP" ]; then
    echo "No Dock backup found at $DOCK_BACKUP. Skipping Dock restore."
    return
  fi

  echo "Restoring Dock configuration from backup..."
  if defaults import com.apple.dock "$DOCK_BACKUP" 2>/dev/null; then
    killall Dock >/dev/null 2>&1 || true
    echo "Dock restored to previous configuration."
  else
    echo "Failed to import Dock settings from backup."
  fi
}

########################################
# DOCK – CUSTOM SETUP FOR YOUR SESSION
########################################

add_app_to_dock() {
  local app_path="$1"
  if [ ! -d "$app_path" ]; then
    echo "Not found (skipping Dock entry): $app_path"
    return 0
  fi

  echo "Adding to Dock: $app_path"
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
  echo "Customizing Dock with selected apps..."

  # Clear out all persistent apps (Finder is special and stays)
  defaults write com.apple.dock persistent-apps -array

  # Add desired apps (only if they exist)
  add_app_to_dock "/Applications/Firefox.app"
  add_app_to_dock "/Applications/Microsoft Word.app"
  add_app_to_dock "/Applications/Microsoft PowerPoint.app"
  add_app_to_dock "/Applications/Microsoft Excel.app"

  # Acrobat variants
  add_app_to_dock "/Applications/Adobe Acrobat.app"
  add_app_to_dock "/Applications/Adobe Acrobat Reader.app"
  add_app_to_dock "/Applications/Adobe Acrobat Reader DC.app"

  # Restart Dock to apply changes
  killall Dock >/dev/null 2>&1 || true
  echo "Dock updated for this session."
}

########################################
# BROWSER TABS & DATA WIPE
########################################

open_login_tabs() {
  echo "Opening login pages in Firefox..."
  open -a "Firefox" "$GOOGLE_LOGIN_URL"
  open -a "Firefox" "$BLACKBOARD_URL"
  open -a "Firefox" "$GITHUB_LOGIN_URL"
}

wipe_personal_data() {
  echo "Wiping your Firefox data for this macOS user..."

  rm -rf "${HOME}/Library/Application Support/Firefox" || true
  rm -rf "${HOME}/Library/Caches/Firefox" || true
  rm -f  "${HOME}/Library/Preferences/org.mozilla.firefox.plist" || true

  echo "Firefox profiles, cache, and prefs removed for this user."

  # NOTE:
  # We do NOT uninstall /Applications/Firefox.app or touch system logs,
  # other browsers, or Microsoft Office data, out of respect for the host machine.
}

########################################
# MAIN – MODES: setup / restore
########################################

MODE="${1:-setup}"

require_macos

case "$MODE" in
  setup)
    echo "=== Guest setup mode ==="
    backup_dock
    ensure_firefox
    open_login_tabs
    customize_dock
    echo "Setup complete."
    ;;
  restore)
    echo "=== Restore & cleanup mode ==="
    wipe_personal_data
    restore_dock
    echo "Cleanup complete."
    ;;
  *)
    echo "Usage:"
    echo "  $0 setup    # backup, install/configure, customize Dock"
    echo "  $0 restore  # wipe your data, restore Dock"
    exit 1
    ;;
esac