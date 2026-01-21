# 🏠 Home Media Server Automator
[![Ubuntu 24.04](https://img.shields.io/badge/OS-Ubuntu_24.04-orange.svg)](https://ubuntu.com/)
[![Podman Quadlets](https://img.shields.io/badge/Engine-Podman_Quadlets-purple.svg)](https://podman.io/)

A scalable, single-click deployment script designed to transform a fresh Ubuntu 24.04 install into a hardened, containerized media server. This project automates system configuration and uses **Podman Quadlets** for modern, rootless service management.

## 🛠 Features
- **Security First:** Automatically verifies SSH public keys and provides the option to disable password authentication to prevent brute-force attacks.
- **Dynamic Deployment:** Automatically detects and deploys every `.container` file located in the `configs/` directory.
- **Web-Based Management:** Installs **Cockpit** with Podman and File Navigator (45Drives) plugins for a full browser-based management experience.
- **Rootless Lifecycle:** Configures Systemd User services and enables **Linger** to ensure 24/7 uptime without requiring root privileges.
- **Variable Injection:** Uses `envsubst` to keep container templates generic while pulling unique server data from a private `variables.env` file.

---

## 🚀 Installation & Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/adityaduggal/home-media-server.git
cd home-media-server
```

### 2. Configure Your Environment
The script requires a `variables.env` file to handle your specific network and storage paths. A template is provided:

```bash
cp variables.env.example variables.env
nano variables.env
```
⚠️ **Security Note:** `variables.env` contains your private IP and system paths. It is strictly ignored by Git via `.gitignore`. Ensure you have run `ssh-copy-id` from your local machine to the server before running the setup to avoid being locked out.

### 3. Run the Setup Script
```bash
chmod +x setup.sh
./setup.sh
```

## 📂 Repository Structure
- **setup.sh:** The master installation and deployment engine.
- **variables.env.example:** Template for your server-specific settings.
- **configs/:** Place your Podman Quadlet files here (e.g., `deluge.container`).
- **.gitignore:** Pre-configured to protect your private environment data.

## ⚙️ Quadlet Workflow
This project utilizes Podman Quadlets, the native way to manage containers on Ubuntu 24.04 via Systemd.

- **Templates:** You define apps in `configs/*.container` using `${VARIABLE_NAME}` placeholders.
- **Processing:** The `setup.sh` script runs `envsubst` to inject your real values from `variables.env`.
- **Generation:** Files are deployed to `~/.config/containers/systemd/`.
- **Lifecycle:** Services are managed via standard systemd commands:

```bash
systemctl --user status <app_name>
systemctl --user restart <app_name>
```

## 📊 Included Applications

This media server setup includes three powerful containerized applications:

### 🎬 **Jellyfin** - Media Server
**Purpose:** Stream your personal media library (movies, TV shows, music, photos) across your network.

- **Web UI:** http://<SERVER_IP>:8096
- **Default Login:** Set via web UI on first access
- **Features:**
  - Free alternative to Plex with no account required
  - Hardware-accelerated video transcoding (Intel QuickSync, AMD VAAPI, NVIDIA)
  - Multi-user support with granular access controls
  - Client apps for streaming on all devices
- **Storage:** Media mounted read-only from `SERVER_MEDIA_DIR`
- **Configuration:** `configs/jellyfin.container`
- **Documentation:** [Jellyfin Official Docs](https://jellyfin.org/docs/)

### 📥 **Deluge** - Torrent Client
**Purpose:** Download content directly to your server via BitTorrent protocol.

- **Web UI:** http://<SERVER_IP>:8112
- **Default Login:** admin / deluge (⚠️ Change immediately after first login!)
- **Features:**
  - Lightweight and efficient torrent client
  - Bandwidth rate limiting to prevent network saturation
  - Automatic download categorization
  - Plugin support for enhanced functionality
- **Storage:** Downloads saved to `SERVER_DOWNLOAD_DIR`
- **Configuration:** `configs/deluge.container`
- **Documentation:** [Deluge Official Docs](https://deluge-torrent.org/)

### 💾 **Duplicati** - Backup & Recovery
**Purpose:** Securely backup your media library and server configurations to local or cloud storage.

- **Web UI:** http://<SERVER_IP>:8200
- **Default Login:** admin / admin (⚠️ Change immediately after first login!)
- **Features:**
  - End-to-end encryption for all backups
  - Compression to reduce storage requirements
  - Incremental backups to minimize bandwidth usage
  - Support for multiple backends: Local, AWS S3, OneDrive, Google Drive, Dropbox, etc.
  - Scheduled automated backups
- **Storage:** Local backups stored in `DUPLICATI_BACKUP_DIR`
- **Configuration:** `configs/duplicati.container`
- **Documentation:** [Duplicati Official Docs](https://duplicati.com/)

## 📊 Management Dashboards
Once the script completes, you can access your server via these interfaces:

- **Cockpit Web UI:** https://<SERVER_IP>:9090 (System management, containers, files)
- **Jellyfin:** http://<SERVER_IP>:8096 (Media streaming)
- **Deluge:** http://<SERVER_IP>:8112 (Torrent downloads)
- **Duplicati:** http://<SERVER_IP>:8200 (Backup management)

## 🛠 Troubleshooting
- **Logs:** To view live logs for any app: `journalctl --user -u <app_name> -f`
- **Permissions:** If you encounter I/O errors on mount points, ensure the `SERVER_USER` defined in your `.env` owns the target directories.
- **Linger:** If containers stop when you log out, verify linger is active: `loginctl user-status <username>`

---

**Created by [adityaduggal](https://github.com/adityaduggal)**