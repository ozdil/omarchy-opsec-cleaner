# 🔒 OpSec Cleaner • Omarchy Image EXIF & Metadata Sanitizer

> **Digital privacy, GPS, and EXIF metadata sanitizer plugin for Omarchy 4.0.2+.**

Author: **Ozan Özdil (ozdil)**  
License: **MIT**

---

## ✨ Features

- 📸 **Supported Image Formats:** Strips EXIF, GPS location, device serial numbers, and software fingerprints from **JPEG** and **PNG** images.
- 🛡️ **Safe Invocation:** Passes file arguments safely via argv without shell string interpolation.
- 🔒 **Decompression Bomb Protection:** Bounded pixel allocation (max 100MP) and input file size limits (max 50MB).
- 📂 **Atomic File Replacement:** Uses exclusive same-directory temporary files followed by `fsync` and collision-free atomic naming.

---

## 📋 Requirements

- `python3` (>= 3.10)
- `python-pillow` (`pip install Pillow` or `pacman -S python-pillow`)
- `zenity` (optional GUI file picker)

---

## 🚀 Installation & Removal

### Installation
```bash
git clone https://github.com/ozdil/omarchy-opsec-cleaner.git ~/.config/omarchy/plugins/opsec-cleaner
chmod +x ~/.config/omarchy/plugins/opsec-cleaner/cleaner-*
```

Add to `~/.config/omarchy/shell.json`:
```json
{
  "id": "opsec-cleaner",
  "exec": "$HOME/.config/omarchy/plugins/opsec-cleaner/cleaner-status",
  "interval": 30,
  "onClick": "omarchy-launch-floating-terminal-with-presentation $HOME/.config/omarchy/plugins/opsec-cleaner/cleaner-dashboard"
}
```

### Removal
```bash
rm -rf ~/.config/omarchy/plugins/opsec-cleaner
# Remove the "opsec-cleaner" entry from ~/.config/omarchy/shell.json and run:
omarchy-restart-shell
```
