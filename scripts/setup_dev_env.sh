#!/bin/bash
# ==============================================================================
# 🛠️ Homelab Dev Environment Setup Script
# ==============================================================================
# Usage: ./setup_dev_env.sh
#
# DESCRIPTION:
#   1. Fixes Proxmox repositories (disables enterprise, enables no-subscription).
#   2. Installs all necessary tools for managing the Homelab Proxmox project:
#      - Terraform
#      - Ansible
#      - Rclone
#      - Git, Curl, Unzip
#
# Supported OS: Debian, Ubuntu, Proxmox VE
# ==============================================================================

set -e

echo "--- 🛠️  Starting Dev Environment Setup ---"

# --- 0. Identify OS Codename (without lsb_release) ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    CODENAME=$VERSION_CODENAME
    # Fallback for older versions or non-standard os-release
    if [ -z "$CODENAME" ]; then
        CODENAME=$(echo "$VERSION" | grep -oP '\(\K[^\)]+' | head -1)
    fi
else
    echo "❌ Error: /etc/os-release not found. Cannot determine OS version."
    exit 1
fi

echo "📍 Detected OS Codename: $CODENAME"

# --- 1. Fix Proxmox Repositories (if on PVE) ---
if [ -f /etc/pve/local/pve-ssl.key ]; then
    echo "--- 🔧 Proxmox VE detected. Fixing repositories ---"
    
    # Disable PVE Enterprise
    if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
        echo "Disabling pve-enterprise repository..."
        sudo sed -i 's/^deb/#deb/g' /etc/apt/sources.list.d/pve-enterprise.list
    fi

    # Disable Ceph Enterprise
    if [ -f /etc/apt/sources.list.d/ceph.list ]; then
        echo "Disabling ceph-enterprise repository..."
        sudo sed -i 's/^deb/#deb/g' /etc/apt/sources.list.d/ceph.list
    fi

    # Enable PVE No-Subscription
    if ! grep -q "pve-no-subscription" /etc/apt/sources.list && ! grep -q "pve-no-subscription" /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "Enabling pve-no-subscription repository..."
        echo "deb http://download.proxmox.com/debian/pve $CODENAME pve-no-subscription" | sudo tee -a /etc/apt/sources.list
    fi

    # Enable Ceph No-Subscription (if Ceph is installed)
    if [ -f /etc/apt/sources.list.d/ceph.list ] && ! grep -q "no-subscription" /etc/apt/sources.list.d/ceph.list; then
         echo "Enabling ceph no-subscription repository..."
         # Default to 'reef' as a safe modern default for Ceph no-sub
         echo "deb http://download.proxmox.com/debian/ceph-reef $CODENAME no-subscription" | sudo tee /etc/apt/sources.list.d/ceph.list
    fi
else
    echo "--- ✨ Standard Debian/Ubuntu detected. Skipping PVE repo fix. ---"
fi

# --- 2. Update and Install Base Tools ---
echo "--- 📦 Updating APT and installing base tools ---"
sudo apt update
sudo apt install -y curl git unzip gnupg software-properties-common

# --- 3. Install Terraform ---
if ! command -v terraform &> /dev/null; then
    echo "--- 🏗️  Installing Terraform ---"
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $CODENAME main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform
else
    echo "✅ Terraform already installed."
fi

# --- 4. Install Ansible ---
if ! command -v ansible &> /dev/null; then
    echo "--- 🛠️  Installing Ansible ---"
    sudo apt update
    sudo apt install -y ansible
else
    echo "✅ Ansible already installed."
fi

# --- 5. Install Rclone ---
if ! command -v rclone &> /dev/null; then
    echo "--- ☁️  Installing Rclone ---"
    curl https://rclone.org/install.sh | sudo bash
else
    echo "✅ Rclone already installed."
fi

echo "--- ✅ Dev Environment Setup Complete! ---"
echo "You can now run './scripts/preflight_check.sh' to verify your configuration."
