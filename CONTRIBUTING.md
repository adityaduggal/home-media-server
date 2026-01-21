# 👨‍💻 Developer Guide - Contributing to Home Media Server

Welcome! This guide explains how to develop, test, and contribute to the Home Media Server project.

## 📚 Table of Contents
1. [Project Structure](#project-structure)
2. [Development Setup](#development-setup)
3. [Project Architecture](#project-architecture)
4. [Code Guidelines](#code-guidelines)
5. [Adding New Services](#adding-new-services)
6. [Testing & Validation](#testing--validation)
7. [Linting & Formatting](#linting--formatting)
8. [Git Workflow](#git-workflow)
9. [Troubleshooting](#troubleshooting)

---

## 📁 Project Structure

```
home-media-server/
├── README.md                          # Main project documentation
├── CONTRIBUTING.md                    # This file - Developer guide
├── setup.sh                           # Main installation & deployment script
├── variables.env.example              # Configuration template
├── Makefile                           # Development tasks (lint, validate, etc.)
├── .editorconfig                      # Editor formatting rules
├── .pre-commit-config.yaml            # Git pre-commit hooks
├── .gitignore                         # Git ignore rules
├── .vscode/
│   ├── extensions.json                # Recommended VS Code extensions
│   └── settings.json                  # VS Code workspace settings
├── configs/
│   ├── jellyfin.container             # Jellyfin media server quadlet
│   ├── deluge.container               # Deluge torrent client quadlet
│   └── duplicati.container            # Duplicati backup solution quadlet
└── .git/                              # Git repository
```

### File Purposes

| File | Purpose |
|------|---------|
| `setup.sh` | Main deployment engine - handles installation, validation, and container deployment |
| `variables.env.example` | Configuration template with all available options and documentation |
| `configs/*.container` | Podman Quadlet definitions for containerized services |
| `Makefile` | Development workflow - linting, validation, formatting |
| `.editorconfig` | Enforces consistent formatting across all file types |
| `.pre-commit-config.yaml` | Automated linting on git commits |

---

## 🛠 Development Setup

### Prerequisites
- Linux machine (Ubuntu 24.04 recommended)
- Git
- Text editor (VS Code recommended)
- Basic understanding of Podman/Docker, Shell scripting, and systemd

### 1. Clone the Repository
```bash
git clone https://github.com/adityaduggal/home-media-server.git
cd home-media-server
```

### 2. Install Development Tools
```bash
# Install linting and formatting tools
make install-tools

# Or manually:
sudo apt-get install shellcheck jq
npm install -g markdownlint-cli prettier
```

### 3. Install Pre-commit Hooks (Optional but Recommended)
```bash
pip install pre-commit
pre-commit install
```

This automatically runs linters and formatters before each commit, ensuring code quality.

### 4. Set Up VS Code (Recommended)
```bash
# VS Code will automatically prompt to install recommended extensions
# Or manually install from .vscode/extensions.json recommendations
code .
```

---

## 🏗 Project Architecture

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│ User runs: ./setup.sh                                       │
└──────────────────┬──────────────────────────────────────────┘
                   │
       ┌───────────┴───────────┐
       ▼                       ▼
   Validation Phase      Deployment Phase
   ├─ Load variables.env  ├─ Install Podman
   ├─ Check SSH keys      ├─ Configure systemd
   ├─ Verify paths        ├─ Process .container files
   └─ Validate config     └─ Enable services

       ┌───────────┴───────────┐
       ▼                       ▼
   For each .container file:
   ├─ Substitute variables (envsubst)
   ├─ Deploy to ~/.config/containers/systemd/
   └─ Enable & start with systemctl
```

### Key Components

**1. Environment Variables (`variables.env`)**
- Stores server-specific configuration
- Never committed to Git (.gitignore)
- Sourced by setup.sh before processing

**2. Podman Quadlets (`configs/*.container`)**
- INI-style systemd unit files for containers
- Use `${VARIABLE_NAME}` placeholders
- Deployed to `~/.config/containers/systemd/`
- Managed via `systemctl --user` commands

**3. Setup Script (`setup.sh`)**
- Validates prerequisites
- Installs dependencies
- Processes and deploys quadlet files
- Sets up systemd user services with linger

---

## 📝 Code Guidelines

### Shell Script Standards

**Use strict mode in all scripts:**
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

**Follow shellcheck recommendations:**
```bash
shellcheck -x script.sh
```

**Quote variables to handle spaces:**
```bash
# Good
if [ -f "$HOME/.ssh/authorized_keys" ]; then

# Bad
if [ -f $HOME/.ssh/authorized_keys ]; then
```

**Use functions for modularity:**
```bash
# Define functions with clear purposes
validate_environment() {
    echo "Validating environment..."
    # validation code
}

# Use descriptive names
check_ssh_keys() { }
deploy_containers() { }
```

### Markdown Standards

- Use consistent heading hierarchy (# → ## → ### → ####)
- Keep lines under 100 characters
- Use backticks for code: `variable_name`, `command`
- Use triple backticks for code blocks with language specified
- Link to external documentation

### Podman Quadlet Standards

**Structure:**
```
[Unit]
Description=<Clear, descriptive title>
After=network-online.target
Wants=network-online.target

[Container]
Image=<image_name>
ContainerName=<name>
# Use ${VARIABLE} for dynamic values
Environment=VAR=${VALUE}
PublishPort=${PORT}:8080
Volume=${PATH}:/container/path:ro  # :ro for read-only

[Service]
Restart=always
RestartMaxDelaySec=5min
MemoryLimit=${MEMORY_LIMIT}
CPUQuota=${CPU_LIMIT}

[Install]
WantedBy=multi-user.target
```

**Guidelines:**
- Document environment variables with comments
- Explain volume mounts (read-only vs read-write)
- Include troubleshooting notes at the end
- Use consistent indentation (spaces, no tabs)

---

## ➕ Adding New Services

To add a new containerized service:

### 1. Create the Quadlet File

Create `configs/service-name.container`:
```ini
[Unit]
Description=My New Service
After=network-online.target
Wants=network-online.target

[Container]
Image=image-name:latest
ContainerName=service-name
Environment=TZ=${TIMEZONE}
PublishPort=${SERVICE_PORT}:8080
Volume=${SERVER_PODMAN_CONFIG_DIR}/service:/config:rw

[Service]
Restart=always
RestartMaxDelaySec=5min
MemoryLimit=${SERVICE_MEMORY_LIMIT}
CPUQuota=${SERVICE_CPU_LIMIT}

[Install]
WantedBy=multi-user.target
```

### 2. Add Configuration to `variables.env.example`

```bash
# ==============================================================================
# [SERVICE_NAME - DESCRIPTION]
# ==============================================================================
# Purpose and features here
#
# Web UI: http://SERVER_IP:SERVICE_PORT

SERVICE_PORT=8080
SERVICE_MEMORY_LIMIT="512M"
SERVICE_CPU_LIMIT="1"
SERVICE_LOG_LEVEL="info"
```

### 3. Update Main README.md

Add service documentation under "Included Applications" section:
```markdown
### 🎯 **Service Name** - Description
**Purpose:** Clear one-liner

- **Web UI:** http://<SERVER_IP>:PORT
- **Default Login:** credentials
- **Features:** Bullet points
- **Configuration:** `configs/service.container`
```

### 4. Test the Quadlet

```bash
# Validate syntax
make validate-container

# Run setup in test mode
./setup.sh

# Check service status
systemctl --user status service-name
systemctl --user logs service-name -f
```

---

## ✅ Testing & Validation

### Pre-commit Validation

All changes should pass these checks:

```bash
# Run all linters
make lint

# Specific linters
make lint-shell        # ShellCheck
make lint-markdown     # Markdownlint
make lint-json         # JSON validation
make lint-container    # Quadlet validation

# Validate all configurations
make validate
make validate-env      # Environment variables
make validate-container # Quadlet structure
```

### Manual Testing

```bash
# Test in isolated environment
docker run -it --rm -v "$PWD:/workspace" ubuntu:24.04 bash
cd /workspace
bash -n setup.sh  # Syntax check
```

### Service Testing

```bash
# Check service status
systemctl --user status jellyfin
systemctl --user status deluge
systemctl --user status duplicati

# View live logs
journalctl --user -u jellyfin -f

# Restart service
systemctl --user restart jellyfin

# Check if service auto-starts on login
loginctl user-status $USER
```

---

## 🎨 Linting & Formatting

### Automatic Linting

When you have pre-commit installed, linters run automatically before commits:

```bash
git commit -m "Add new feature"
# → Pre-commit hooks run automatically
# → If checks fail, commit is blocked
# → Fix issues and try again
```

### Manual Linting

```bash
# Run all checks
make lint

# Fix formatting
make format

# Skip pre-commit for a commit (use sparingly!)
git commit --no-verify
```

### Linters Used

| File Type | Linter | Command |
|-----------|--------|---------|
| Shell | ShellCheck | `shellcheck setup.sh` |
| Markdown | markdownlint | `markdownlint README.md` |
| JSON | jq | `jq . config.json` |
| YAML | yamllint | `yamllint .pre-commit-config.yaml` |
| Format | Prettier | `prettier --write file` |

---

## 🔄 Git Workflow

### Branch Naming Convention

```
feature/description      # New feature
fix/bug-description      # Bug fix
docs/update-readme       # Documentation
refactor/improve-script  # Code refactoring
test/add-validation      # Tests
```

### Commit Message Format

```
<type>: <short description (50 chars max)>

<optional longer description explaining why/what>

Fixes #123
```

### Example Workflow

```bash
# Create feature branch
git checkout -b feature/add-lidarr-service

# Make changes
nano configs/lidarr.container
nano variables.env.example

# Check before committing
make lint
make validate

# Commit
git add configs/lidarr.container variables.env.example
git commit -m "feat: add Lidarr music server service

- Creates Lidarr quadlet configuration
- Adds environment variables for port and memory
- Documents service in variables.env.example"

# Push to GitHub
git push origin feature/add-lidarr-service

# Create Pull Request on GitHub
```

---

## 🐛 Troubleshooting

### Common Issues

**Issue: ShellCheck not installed**
```bash
# Solution
sudo apt-get install shellcheck
# or
make install-tools
```

**Issue: Pre-commit hook fails before commit**
```bash
# View what failed
pre-commit run --all-files

# Fix issues and retry
git add fixed-files
git commit -m "message"

# Skip if absolutely necessary (avoid!)
git commit --no-verify
```

**Issue: Variable not substituted in quadlet**
```bash
# Check if variable is defined in variables.env.example
grep "MY_VAR=" variables.env.example

# Check quadlet uses correct syntax
grep '\${MY_VAR}' configs/service.container

# Re-run setup
./setup.sh
```

**Issue: Service won't start after deployment**
```bash
# Check logs
journalctl --user -u service-name -f

# Validate quadlet
systemctl --user cat service-name

# Ensure config directory exists
mkdir -p ~/.config/containers/systemd
ls -la ~/.config/containers/systemd/
```

### Debug Commands

```bash
# Check script syntax without executing
bash -n setup.sh

# Source variables to test them
source variables.env.example
echo $SERVER_IP

# Test envsubst substitution
envsubst < configs/jellyfin.container | head -20

# Validate all JSON files
jq . .vscode/extensions.json

# Test shell functions
source setup.sh
check_ssh_keys  # Run specific function
```

---

## 📖 Additional Resources

- [Podman Quadlets Documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- [systemd User Services](https://wiki.archlinux.org/title/Systemd/User)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [EditorConfig Format](https://editorconfig.org/)
- [Prettier Documentation](https://prettier.io/docs/en/index.html)

---

## ❓ Questions?

If you encounter issues or have questions:
1. Check this guide and [Troubleshooting](#troubleshooting) section
2. Review the inline comments in configuration files
3. Check service logs: `journalctl --user -u <service> -f`
4. Open an issue on [GitHub](https://github.com/adityaduggal/home-media-server/issues)

---

**Happy coding! 🚀**
