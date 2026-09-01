# 🔒 Omarchy OpSec Cleaner Plugin

> **Digital privacy & OpSec metadata scrubber for Omarchy 4.0.2+.**

Author: **Ozan Özdil (ozdil)**  
License: **MIT**

---

## ✨ Features

- 📍 **GPS & Location Stripping:** Removes all geographical coordinates, altitude, and GPS timestamps from photos.
- 📱 **Hardware & Camera Sanitization:** Scrubs camera manufacturer, lens info, device serial numbers, and software signatures.
- ⚡ **Pure-Python & Instant:** High-speed metadata stripping without altering image dimensions or quality.
- 🖥️ **One-Click File Selection:** Integrated file picker with instant before/after metadata inspection.

---

## 🚀 Installation

```bash
# Clone to Omarchy plugins directory
git clone https://github.com/ozdil/omarchy-opsec-cleaner.git ~/.config/omarchy/plugins/opsec-cleaner
chmod +x ~/.config/omarchy/plugins/opsec-cleaner/cleaner-*
```

Add `{"id": "opsec-cleaner", "exec": "$HOME/.config/omarchy/plugins/opsec-cleaner/cleaner-status", "onClick": "omarchy-launch-floating-terminal-with-presentation $HOME/.config/omarchy/plugins/opsec-cleaner/cleaner-dashboard"}` to `~/.config/omarchy/shell.json`.
