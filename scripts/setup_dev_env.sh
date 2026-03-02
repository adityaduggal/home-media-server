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
# Check for PVE by looking for common PVE files or the enterprise repo string
if [ -f /etc/pve/local/pve-ssl.key ] || grep -qri "enterprise.proxmox.com" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
    echo "--- 🔧 Proxmox VE components detected. Fixing repositories ---"
    
    # Aggressively disable any enterprise repositories in all apt sources
    echo "Disabling enterprise repositories..."
    # Find all files containing enterprise.proxmox.com and comment out those lines
    sudo grep -rl "enterprise.proxmox.com" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | while read -r file; do
        echo "Found enterprise repo in $file - commenting out..."
        sudo sed -i 's/^\s*deb/# deb/g' "$file"
    done

    # Enable PVE No-Subscription if not already present
    if ! grep -qri "pve-no-subscription" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
        echo "Enabling pve-no-subscription repository..."
        echo "deb http://download.proxmox.com/debian/pve $CODENAME pve-no-subscription" | sudo tee /etc/apt/sources.list.d/pve-no-sub.list
    fi

    # Enable Ceph No-Subscription if not already present
    if ! grep -qri "no-subscription" /etc/apt/sources.list.d/ 2>/dev/null | grep -v "pve-no-subscription"; then
         echo "Enabling ceph no-subscription repository..."
         # Detect if we should use squid (Proxmox 8.x/9.x) or reef (Proxmox 8.x)
         CEPH_VERSION="reef"
         if grep -qi "ceph-squid" /etc/apt/sources.list.d/* 2>/dev/null; then
            CEPH_VERSION="squid"
         fi
         echo "deb http://download.proxmox.com/debian/ceph-$CEPH_VERSION $CODENAME no-subscription" | sudo tee /etc/apt/sources.list.d/ceph-no-sub.list
    fi
else
    echo "--- ✨ Standard Debian/Ubuntu detected. Skipping PVE repo fix. ---"
fi

# --- 2. Update and Install Base Tools ---
echo "--- 📦 Updating APT and installing base tools ---"
# Use --allow-releaseinfo-change in case the user is on a testing branch (like trixie)
sudo apt update || sudo apt update --allow-releaseinfo-change
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
