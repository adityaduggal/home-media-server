## 🌐 Network Map (should be parametric for changes to be allowed in a file easily)
- **Prod Host (j1103):** 10.3.0.5
- **Dev Host:** 10.3.0.11
- **Subnet:** 10.3.0.0/24
- **Domain** j1103.in
- **Sub Domains** should be accessible only by local networ with Naked and wildcard certificates
    - Local sub-domains should be get redirected to full url if we type shortname/ in browser URL
        - Example: jellyfin.j1103.in we should only type jellyfin/ in browser URL to get redirected

## 🔐 Security & Repo Rules
- **No-Subscription:** Always use `pve-no-subscription` components.
- **Secrets:** Use `.env` for Terraform and `ansible-vault` for Ansible.
- **Root Access:** Use `become: yes` for Ansible; use `sudo` for shell.
- **SSL:** Ignore SSL verification for local Proxmox API calls (self-signed certs)
- **SSL** Obtain a certificate if the certificate is possible for domain from Letsencrypt.

## 📂 Project Structure
- `/terraform`: VM and LXC definitions
- `/ansible/dev`: Development inventory and vars
- `/ansible/prod`: Production inventory and vars

## Applications to Be Used
    - Traefic for reverse proxy (proxy{{ dev_suffix }}.domain_name)
        - Auto provisioning of Traefic on creation of LXC or VM in Proxmox
        - All the lxc and vm would have tags in notes for 
    - Jellyfin for streaming (jellyfin{{ dev_suffix }}.domain_name and media{{ dev_suffix }}.domain_name)
    - Deluge for Torrent Client (deluge{{ dev_suffix }}.domain_name, torrent{{ dev_suffix }}.domain_name)
    - Radarr for Movies (radarr{{ dev_suffix }}.domain_name, movies{{ dev_suffix }}.domain_name)
    - Sonarr for TV Shows (sonarr{{ dev_suffix }}.domain_name, tv{{ dev_suffix }}.domain_name)
    - Prowlarr for Indexing of Sources (prowlarr{{ dev_suffix }}.domain_name, index{{ dev_suffix }}.domain_name)
    - Bazarr for Managing Subtitles (bazarr{{ dev_suffix }}.domain_name, subtitles{{ dev_suffix }}.domain_name)
    - Flaresolverr for solving needed for certain sources in Prowlarr
    - Jellyserr for Requests for new media content (jellyserr{{ dev_suffix }}.domain_name, requests{{ dev_suffix }}.domain_name)
    - Recyclarr for Sync Profiles for Security (recyclarr{{ dev_suffix }}.domain_name, sync{{ dev_suffix }}.domain_name)
    - Home Assistant for Smart Home (homeassistant{{ dev_suffix }}.domain_name, home{{ dev_suffix }}.domain_name)

## Application Settings
    - All the above application settings should be installed in a click.
    - We are dealing with Infra as Code and Software installation as code
    
## Backup
    - We need to back settings for all applications so that in case of failure we can restore easily
    - Backup restore should be one click
    - Backup should be automated on Cloud like Google Drive
    - We can skip the Database for certain applications if the backup size becomes huge.


## Documentation
    - Readme.MD for detailed instructions for New Installation, Backup and Restore.
    - Every application to have its documentation separately with regards to instructions to setup
    - Every apps docs should define their ports etc

## Goal
    - To improve this system by adding more and more services to it but installation should be one click
    - 