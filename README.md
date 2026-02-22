# ❄️ Le Frigo - GitOps Infrastructure 

Welcome to the official repository of Le Frigo (The Fridge). This project manages a complete home server infrastructure using Docker Compose and a GitOps approach via Portainer.

## 🏗️ Architecture Overview
The infrastructure is segmented into 5 logical stacks to ensure high availability, easier maintenance, and clear separation of concerns.

### 01-Core (The Foundation)
The backbone of the server, providing networking, security, and shared databases.

- Traefik: Reverse proxy with automatic TLS (Let's Encrypt).

- Authentik: Identity and Access Management (SSO).

- Postgres & Redis: Shared databases for all stacks.

- Tailscale: Secure mesh VPN for remote management.

### 02-Multimedia
The entertainment hub.

- Jellyfin: Movie and TV show streaming.

- Navidrome: High-performance music server.

- Immich: Self-hosted photo and video backup solution.

- Kavita: Digital library for books and manga.

### 03-Downloads (The Bastion)
Secure media acquisition behind a VPN.

- Gluetun: VPN Gateway (Wireguard/ProtonVPN) with Kill Switch.

- qBittorrent: Torrent client routed through Gluetun.

- Radarr & Sonarr: Automatic movie and series management.

- Prowlarr: Indexer manager for the Arrs.

### 04-Tools
Productivity and utility services.

- Outline: Modern team knowledge base (Wiki).

- Filebrowser: Web-based file manager with Authentik SSO.

- Wallos: Personal subscription tracker.

- BentoPDF & ConvertX: PDF and file conversion utilities.

- ntfy: Self-hosted notification service.

- pgAdmin: Graphical administration for Postgres.

### 05-Monitoring
Health and safety services.

- Uptime Kuma: Monitoring and status pages.

- What's Up Docker (WUD): Automated container update alerts.

- Backrest: Web UI for Restic backups with SSH support.

## ⚙️ Setup & Configuration
### Environment Variables
Each stack relies on a local `.env` file based on the provided `.env`.example. Key variables include:

- `APPS_DATA_DIR`: Root path for application configurations.

- `MEDIA_DATA_DIR`: Root path for media storage.

- `PUID/PGID`: User/Group IDs to ensure correct permissions.

### Networking
All stacks communicate through a single external Docker network: lefrigo-net.

## 🚀 Deployment
Clone this repository to your NAS.

Configure your .env files for each directory.

Deploy via Portainer by linking this repository to 5 distinct stacks using the path to each `docker-compose.yml`.
