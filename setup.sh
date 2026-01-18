#!/bin/bash

# --- 1. VARIABLES (Dynamic Options) ---
# You can move these to variables.env later
SERVER_NAME="duggals"
SERVER_IP="10.3.0.5"
SERVER_USER="aditya"
MEDIA_DIR="/home_media"
PODMAN_CONFIG_DIR="/opt/aditya/podman_configs"
TIMEZONE="Asia/Kolkata"

echo "--- Starting Home Media Server Setup for $SERVER_NAME ---"

# --- 2. TIMEZONE SETUP ---
echo "[*] Checking Timezone..."
CURRENT_TZ=$(cat /etc/timezone)
if [ "$CURRENT_TZ" != "$TIMEZONE" ]; then
    read -p "Current TZ is $CURRENT_TZ. Change to $TIMEZONE? (y/n) " tz_answer
    if [ "$tz_answer" == "y" ]; then
        sudo timedatectl set-timezone $TIMEZONE
        echo "Timezone updated."
    fi
fi

# --- 3. SSH SECURITY (Keys vs Passwords) ---
echo "[*] Checking SSH Configuration..."
if [ ! -f ~/.ssh/authorized_keys ]; then
    echo "CRITICAL: No public keys found in ~/.ssh/authorized_keys."
    echo "HELP: Please run 'ssh-copy-id' from your local machine before disabling passwords."
else
    echo "Public key found. Checking if password login is disabled..."
    if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
        read -p "Password login is currently ENABLED. Disable it now? (y/n) " ssh_answer
        if [ "$ssh_answer" == "y" ]; then
            sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
            sudo systemctl restart ssh
            echo "Password authentication disabled."
        fi
    fi
fi

# --- 4. INSTALL COCKPIT & PLUGINS ---
echo "[*] Setting up Cockpit and Podman..."
sudo apt update && sudo apt install -y cockpit cockpit-podman podman podman-compose

# Check for Cockpit-File-Sharing (The best file manager for Cockpit)
if [ ! -d "/usr/share/cockpit/file-sharing" ]; then
    echo "Installing Cockpit File Sharing plugin..."
    # Commands to download/install the specific .deb for the navigator
    # (e.g., wget from 45Drives/cockpit-navigator)
fi

# --- 5. PODMAN CONFIGS & REGISTRIES ---
mkdir -p $PODMAN_CONFIG_DIR
# Custom Registry Example
if [ ! -f /etc/containers/registries.conf ]; then
    echo "[*] Setting up custom registries..."
    # Append custom registry logic here
fi

# --- 6. DELUGE & JELLYFIN SETUP ---
echo "[*] Deploying Media Containers..."
# Set permissions for media dir
sudo chown -R $SERVER_USER:$SERVER_USER $MEDIA_DIR
sudo chmod -R 775 $MEDIA_DIR

# Trigger Podman to run containers based on your repo files
# podman-compose -f configs/deluge.yml up -d

echo "--- Setup Complete! Access Cockpit at https://$SERVER_IP:9090 ---"