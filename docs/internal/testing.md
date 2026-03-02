# 🧪 Internal Testing Procedures

This document outlines the internal testing protocols for the `homelab-proxmox` project, ensuring infrastructure and configuration changes are validated before production deployment.

## 🏗️ Development Environment (Dev)

The Dev environment is a **Nested Proxmox** instance or a dedicated physical node (IP: `10.3.0.11`) used to mirror the production topology.

### 0. Defining Variables for Testing
All environment-specific variables are defined in the following locations:
1.  **Global Secrets:** `.env` (Copy from `.env.example`).
2.  **Dev-Specific Overrides:** `ansible/inventories/dev/group_vars/all.yml`.
    - `dev_suffix: "-dev"`: This appends `-dev` to all subdomains (e.g., `radarr-dev.j1103.in`).
    - `network_prefix: "10.3.99"`: Ensures Dev LXCs don't conflict with Prod.

### 1. Provisioning Dev Infrastructure
To test Terraform module changes:
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 2. Ansible Configuration Testing
Test playbooks against the dev inventory:
```bash
# Verify connectivity
ansible -i ansible/inventories/dev all -m ping

# Run deployment in check mode
ansible-playbook -i ansible/inventories/dev ansible/playbooks/deploy_stack.yml --check

# Full deployment to Dev
ansible-playbook -i ansible/inventories/dev ansible/playbooks/deploy_stack.yml
```

### 3. Service Verification
Since Dev uses suffixed subdomains (e.g., `radarr-dev.j1103.in`), override your local DNS to point to the Dev Traefik IP (`10.3.99.101` in Dev).

**Example `/etc/hosts`:**
```text
10.3.99.101  radarr-dev.j1103.in sonarr-dev.j1103.in jellyfin-dev.j1103.in
```

## 🛠️ Automated Checks (Pre-flight)

Before any commit or deployment, run the pre-flight script to validate your local environment:
```bash
./scripts/preflight_check.sh
```

This script verifies:
- Presence of `.env` and `.vault_pass`.
- Terraform binary and provider versions.
- Ansible connectivity and vault encryption status.

## 🔄 CI/CD Simulation (Dry-Run)

Simulate a full deployment lifecycle without making permanent changes:
```bash
./scripts/bootstrap.sh --dry-run
```
