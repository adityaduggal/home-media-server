#!/bin/bash

# ==============================================================================
# Home Media Server Automator - Scalable Single-Click Deployment
# ==============================================================================
#
# PURPOSE:
#   Automates the complete setup of a hardened, containerized media server on
#   Ubuntu 24.04 using Podman Quadlets and Systemd User services.
#
# FEATURES:
#   - Loads and validates environment variables from variables.env
#   - Checks SSH public keys for secure access
#   - Configures system timezone
#   - Installs and configures Podman, Cockpit, and dependencies
#   - Dynamically deploys all .container files from configs/ directory
#   - Sets up rootless systemd user services with linger enabled
#   - Provides final status report with service dashboards
#
# PREREQUISITES:
#   - Ubuntu 24.04 LTS
#   - SSH public key added to ~/.ssh/authorized_keys
#   - variables.env file configured (copy from variables.env.example)
#   - sudo access
#
# USAGE:
#   chmod +x setup.sh
#   ./setup.sh
#
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

# Check if SSH public keys are configured for secure access
# Returns 0 if keys exist, 1 if missing (user prompted to continue or abort)
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

# Verify and set system timezone to match TIMEZONE variable
# Updates timedatectl if current timezone differs
    echo "⏰ Checking Timezone..."
    CURRENT_TZ=$(timedatectl show --property=Timezone --value)
    if [ "$CURRENT_TZ" != "$TIMEZONE" ]; then
        sudo timedatectl set-timezone "$TIMEZONE"
        echo "✅ Timezone updated to $TIMEZONE."
    fi
}

# --- 3. SYSTEM INSTALLATION ---
# Update package manager and install core dependencies:
#   - cockpit: Web-based server management interface
#   - cockpit-podman: Podman integration for Cockpit
#   - podman: Container engine (rootless)
#   - curl, wget: Download utilities
#   - gettext: For envsubst variable substitution
echo "🔄 Updating system and installing dependencies..."
sudo apt update && sudo apt install -y cockpit cockpit-podman podman curl wget gettext

# Cockpit Navigator Installation
# Adds a file browser plugin to Cockpit for easy directory navigation
if [ ! -d "/usr/share/cockpit/navigator" ]; then
    echo "📂 Installing Cockpit Navigator (file browser plugin)..."
    wget -q https://github.com/45Drives/cockpit-navigator/releases/latest/download/cockpit-navigator_0.5.10-1focal_all.deb -O /tmp/navigator.deb
    sudo apt install -y /tmp/navigator.deb
    rm /tmp/navigator.deb
fi

# Run system checks and security hardening
# - Configure timezone if different from system setting
# - Verify SSH keys and optionally disable password authentication
# - Enable loginctl linger for persistent systemd user services
configure_timezone
if check_ssh_keys && [ "$DISABLE_SSH_PASSWORDS" = "true" ]; then
    echo "🔒 Hardening SSH..."
    sudo sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart ssh
fi

# Enable linger: keeps systemd user services running even when user is logged out
# Required for 24/7 uptime without root privileges
sudo loginctl enable-linger $USER

# --- 4. DIRECTORY & PERMISSIONS SETUP ---
# Create necessary directories and set ownership
# - SERVER_MEDIA_DIR: Root directory for all media storage
# - SERVER_PODMAN_CONFIG_DIR: Container configuration directories
# Create media and config base dirs
sudo mkdir -p "$SERVER_MEDIA_DIR" "$SERVER_PODMAN_CONFIG_DIR"
sudo chown -R $USER:$USER "$SERVER_MEDIA_DIR" "$SERVER_PODMAN_CONFIG_DIR"
echo "✅ Directories prepared: $SERVER_MEDIA_DIR"

# --- 5. DYNAMIC APP DEPLOYMENT (THE LOOP) ---
# This is the core deployment mechanism:
# - Scans configs/ directory for all .container files (Podman Quadlets)
# - Performs variable substitution using envsubst (${VARIABLE_NAME} → actual values)
# - Deploys processed files to ~/.config/containers/systemd/ for systemd discovery
QUADLET_DIR="$HOME/.config/containers/systemd"
mkdir -p "$QUADLET_DIR"

echo "📦 Deploying App Containers..."

# Loop through all .container files in the configs directory
# Each .container file defines a Podman Quadlet service
for container_file in configs/*.container; do
    [ -e "$container_file" ] || continue # Handle empty directory
    
    APP_NAME=$(basename "$container_file" .container)
    echo "  -> Deploying $APP_NAME..."

    # 1. Create specific config sub-folder for the app (stores persistent data)
    mkdir -p "$SERVER_PODMAN_CONFIG_DIR/$APP_NAME"

    # 2. Use envsubst to replace all ${VARIABLE_NAME} placeholders with values from variables.env
    # 3. Save processed file to systemd user service directory for automatic detection
    envsubst < "$container_file" > "$QUADLET_DIR/$APP_NAME.container"
done

# --- 6. START SERVICES ---
# Reload systemd to discover new .container files and start all services
# Each service will be enabled (auto-start on boot) and started immediately
echo "⚙️  Refreshing Systemd and starting services..."
systemctl --user daemon-reload

# Enable and start all apps found in the configs folder
# Services will persist across reboots and user logouts (due to linger)
for container_file in configs/*.container; do
    [ -e "$container_file" ] || continue
    APP_NAME=$(basename "$container_file" .container)
    systemctl --user enable --now "$APP_NAME"
    echo "✅ $APP_NAME service is active."
done


# --- 7. FINAL STATUS REPORT ---
# Display setup completion summary with access information and service details
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
    
    # Display service info with appropriate status symbol
    if [ "$STATUS" = "active" ]; then
        echo "✅ $APP_NAME (http://$SERVER_IP:$PORT_VAL)"
    else
        echo "❌ $APP_NAME - Status: $STATUS"
    fi
done

echo "-------------------------------------------------------"
echo ""
echo "🎉 Setup Complete! Access your services:"
echo "   📊 Cockpit Dashboard:  https://$SERVER_IP:9090"
echo "   📁 File Manager:       https://$SERVER_IP:9090/cockpit/@localhost/files"
echo ""
echo "📝 Next Steps:"
echo "   1. Add more .container files to the configs/ directory"
echo "   2. Run the setup script again to deploy new services"
echo "   3. Use 'systemctl --user status' to check service status"
echo ""
echo "💡 Helpful Commands:"
echo "   View logs:    journalctl --user -u <service_name> -f"
echo "   Restart:      systemctl --user restart <service_name>"
echo "   Enable Linger: loginctl show-user $USER | grep Linger"
echo "-------------------------------------------------------"