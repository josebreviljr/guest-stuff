# Guest Mac Setup Script

This repository contains a lightweight, **no-dependencies**, macOS-native bash script that configures any guest or public Mac for quick use — and then restores it back to its original state when you're done.

The goal:  
**Curl → Run → Work → Restore → Leave No Trace**

---

## ✨ Features

### **Setup Mode (`setup`)**
- Installs **Firefox** automatically if it is not already installed.
- Opens login tabs for:
  - Google  
  - Blackboard  
  - GitHub  
- Reconfigures the Dock to show only:
  - Finder (macOS default)
  - Firefox  
  - Microsoft Word  
  - Microsoft PowerPoint  
  - Microsoft Excel  
  - Adobe Acrobat (or Acrobat Reader)
- **Backs up the current Dock configuration** so it can be restored later.

### **Restore Mode (`restore`)**
- Wipes all personal Firefox data for the current user:
  - Profiles  
  - Cache  
  - Preferences  
- Restores the Dock to its **original** layout using the backup created during setup.

### **Zero external packages**
The script uses only built-in macOS tools:
`bash`, `curl`, `hdiutil`, `defaults`, `killall`, `rm`, `open`.

No Homebrew, no dockutil, no third-party software.

---

## 📦 Backup Location

Backups are stored in:
~/.guest_env_backup/dock.plist

This folder is created automatically during setup and reused during restore.

---

## 🚀 Usage

### **1. Setup the guest Mac**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/<YOUR_USERNAME>/guest-mac-setup/main/setup-guest-mac.sh) setup ```

### **2. Restore the guest Mac**

```bash <(curl -fsSL https://raw.githubusercontent.com/<YOUR_USERNAME>/guest-mac-setup/main/setup-guest-mac.sh) restore```
