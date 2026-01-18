# 🏠 Home Media Server Automator

An all-in-one script to transform a fresh Ubuntu 24.04 install into a high-performance, containerized media server.

## 🚀 Quick Start
1. **Clone the repo:**
   `git clone https://github.com/adityaduggal/home-media-server.git`
2. **Set your variables:** Edit `setup.sh` or `variables.env`.
3. **Run the installer:** `chmod +x setup.sh && ./setup.sh`

## 🛠 Features
- **Hardened SSH:** Enforces Key-based auth and disables passwords.
- **Cockpit Integration:** Web-based GUI for Podman and File Management.
- **Podman Native:** Uses Podman instead of Docker for rootless, daemon-less security.
- **Optimized for Ubuntu 24.04:** Handles FUSE/SSHFS/Z-flags automatically.

## 📂 Core Apps
- **Deluge:** BitTorrent client with Web UI.
- **Jellyfin:** The open-source media system.
- **Cockpit Navigator:** Full file explorer in the browser.