#!/bin/bash

# ==============================================================================
# Home Media Server Automator (Scalable Version)
# ==============================================================================

# --- 1. LOAD ENVIRONMENT VARIABLES ---
if [ ! -f variables.env ]; then
    echo "❌ Error: variables.env not found!"
    echo "Please run: cp variables.env.example variables.env"
    exit 1
fi

set -a
source ./variables.env
set +a

echo "🚀 Starting Setup for Server: $SERVER_NAME ($SERVER_IP)"

# --- 2. HELPER FUNCTIONS ---

check_ssh_keys() {
    echo "🔍 Checking for SSH Public Keys..."
    if [ ! -f "$HOME/.ssh/authorized_keys" ] || [ ! -s "$HOME/.ssh/authorized_keys" ]; then
        echo "⚠️  CRITICAL: NO PUBLIC KEYS DETECTED."
        read -p "Continue WITHOUT disabling passwords? (y/n) " cont_ssh
        [[ ! $cont_ssh =~ ^[Yy]$ ]] && exit 1
        return 1
    else
        echo "✅ SSH Public Key verified."
        return 0
    fi
}

configure_timezone() {
    echo "⏰ Checking Timezone..."
    CURRENT_TZ=$(timedatectl show --property=Timezone --value)
    if [ "$CURRENT_TZ" != "$TIMEZONE" ]; then
        sudo timedatectl set-timezone "$TIMEZONE"
        echo "✅ Timezone updated to $TIMEZONE."
    fi
}

# --- 3. SYSTEM INSTALLATION ---
echo "🔄 Updating system and installing dependencies..."
sudo apt update && sudo apt install -y cockpit cockpit-podman podman curl wget gettext

# Cockpit Navigator Installation
if [ ! -d "/usr/share/cockpit/navigator" ]; then
    echo "📂 Installing Cockpit Navigator..."
    wget -q https://github.com/45Drives/cockpit-navigator/releases/latest/download/cockpit-navigator_0.5.10-1focal_all.deb -O /tmp/navigator.deb
    sudo apt install -y /tmp/navigator.deb
    rm /tmp/navigator.deb
fi

# Run System Checks
configure_timezone
if check_ssh_keys && [ "$DISABLE_SSH_PASSWORDS" = "true" ]; then
    echo "🔒 Hardening SSH..."
    sudo sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart ssh
fi

# Ensure Linger is enabled so containers run without active SSH session
sudo loginctl enable-linger $USER

# --- 4. DIRECTORY & PERMISSIONS SETUP ---
echo "📁 Preparing directories..."
# Create media and config base dirs
sudo mkdir -p "$SERVER_MEDIA_DIR" "$SERVER_PODMAN_CONFIG_DIR"
sudo chown -R $USER:$USER "$SERVER_MEDIA_DIR" "$SERVER_PODMAN_CONFIG_DIR"

# --- 5. DYNAMIC APP DEPLOYMENT (THE LOOP) ---
QUADLET_DIR="$HOME/.config/containers/systemd"
mkdir -p "$QUADLET_DIR"

echo "📦 Deploying App Containers..."

# Loop through all .container files in the configs directory
for container_file in configs/*.container; do
    [ -e "$container_file" ] || continue # Handle empty directory
    
    APP_NAME=$(basename "$container_file" .container)
    echo "  -> Deploying $APP_NAME..."

    # 1. Create specific config sub-folder for the app
    mkdir -p "$SERVER_PODMAN_CONFIG_DIR/$APP_NAME"

    # 2. Use envsubst to swap ${VARIABLES} and save to systemd path
    envsubst < "$container_file" > "$QUADLET_DIR/$APP_NAME.container"
done

# --- 6. START SERVICES ---
echo "⚙️  Refreshing Systemd and starting services..."
systemctl --user daemon-reload

# Enable and start all apps found in the configs folder
for container_file in configs/*.container; do
    [ -e "$container_file" ] || continue
    APP_NAME=$(basename "$container_file" .container)
    systemctl --user enable --now "$APP_NAME"
    echo "✅ $APP_NAME service is active."
done


# --- 7. FINAL STATUS REPORT ---
echo ""
echo "-------------------------------------------------------"
echo "🏁 SETUP COMPLETE - SERVICE SUMMARY"
echo "-------------------------------------------------------"
echo "Server Name:  $SERVER_NAME"
echo "Cockpit UI:   https://$SERVER_IP:9090"
echo "-------------------------------------------------------"

# Loop through the config files again to check status and show ports
for container_file in configs/*.container; do
    [ -e "$container_file" ] || continue
    APP_NAME=$(basename "$container_file" .container)
    
    # Enable and start the service
    systemctl --user enable --now "$APP_NAME" > /dev/null 2>&1
    
    # Determine the status
    STATUS=$(systemctl --user is-active "$APP_NAME")
    
    # Get the port from the env variables (dynamic lookup)
    # We look for a variable named APPNAME_PORT (e.g., JELLYFIN_PORT)
    VAR_NAME=$(echo "${APP_NAME}_PORT" | tr '[:lower:]' '[:upper:]')
    PORT_VAL=${!VAR_NAME}