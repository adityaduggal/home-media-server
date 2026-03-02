# 🧪 Development Environment Testing Guide

This environment allows you to test infrastructure changes on a Nested Proxmox VM before deploying to Production.

## 1. Setup the Dev Host

1. Create a VM on your Prod Proxmox (`10.3.0.5`).
    - **OS:** Proxmox VE ISO
    - **CPU:** Enable "Nested Virtualization" (host CPU type).
    - **RAM:** 16GB+
    - **Disk 1:** 32GB (OS)
    - **Disk 2:** 100GB (Mock Data)
    - **Network:** Bridge to main network.
    - **Static IP:** `10.3.0.11`

## 2. Running Ansible in Dev

Use the `-i` flag to point to the dev inventory.

```bash
# Test connection
ansible -i ansible/inventories/dev all -m ping

# Deploy the full stack to Dev
ansible-playbook -i ansible/inventories/dev ansible/site.yml
```

## 3. Verifying Services

Since Dev uses suffixed subdomains (e.g., `radarr-dev.j1103.in`), you must override DNS locally on your testing machine to access the Dev instance.

**Edit your local `/etc/hosts` or Windows Hosts file:**

```text
10.3.99.101  radarr-dev.j1103.in sonarr-dev.j1103.in jellyfin-dev.j1103.in
```
