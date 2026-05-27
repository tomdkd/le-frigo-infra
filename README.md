# LeFrigo - Homelab Infrastructure
This repository contains the GitOps and Docker Compose configurations for the LeFrigo infrastructure, hosted on a TrueNAS SCALE system.

## Overview
LeFrigo is a multi-stack self-hosted environment built around architecture isolation, security firewalls, and centralized identity management.

- Reverse Proxy: Traefik v3 (handling automated Let's Encrypt SSL certificates).

- Identity Provider (SSO): Authentik (protecting internal routes via ForwardAuth or native OpenID Connect).

- Storage & Permissions: Data persistence is mapped via host directory binds using unified execution masks (PUID/PGID).

## Available Stacks & Applications
The infrastructure is broken down into 6 logical deployment stacks:

### 1. SSO (01-sso)
Handles core identity management and edge route authentication.

- authentik-server / authentik-worker: Core IAM portal and task processors.

- authentik-db: Dedicated PostgreSQL 16 instance.

- docker-proxy-authentik: Isolated socket proxy restricting Docker API access.

### 2. Core (02-core)
The technical backbone of the server.

- traefik: Ingress controller and SSL termination gateway.

- docker-proxy-read: Read-only Docker socket proxy for Traefik service discovery.

- postgres-common: Central multi-tenant PostgreSQL database.

- common-redis: Shared in-memory caching engine.

### 3. Multimedia (03-multimedia)
Entertainment, streaming, and personal archiving platforms.

- jellyfin: Video streaming server (including Stuck In Yesterday band media libraries).

- navidrome: Music server featuring split routing (SSO for Web UI, token-auth for Subsonic APIs).

- immich-server / immich-db: Photo management and backup (decoupled from ML to save RAM).

- audiobookshelf: Audiobooks and podcasts streaming platform.

### 4. Downloads (04-downloads)
Automated media acquisition pipeline.

- gluetun: WireGuard VPN client encapsulating target containers.

- qbittorrent: Torrent client sandboxed inside Gluetun's network namespace.

- prowlarr / radarr / sonarr: Indexer management and automated content monitors.

- ygege / shelfmark: Auxiliary search and ebook utilities.

### 5. Tools (05-tools)
Productivity, documentation, and home automation utilities.

- outline: Wiki workspace integrated with Authentik OIDC and postgres-common.

- mealie: Recipe manager with native Authentik OIDC auto-redirects.

- jellyseerr: Media request manager.

- homeassistant: Smart home automation platform.

- code-server: Web-based IDE mapping the deployment workspace directory.

### 6. Monitoring (06-monitoring)
High availability, backup strategies, and remote access.

- uptime-kuma: Infrastructure health check monitoring panel.

- backrest: Privileged Restic backup orchestrator targeting local datasets and offsite mirrors.

- tailscale: Mesh VPN node running in host network mode.

# Local Development & Operations
## Local Architecture Behavior
Local development mimics the production GitOps behavior by using Dockhand as a base layer. When starting any stack locally, the automation workflow dynamically:
- Copies the stack's local environment example (`stack.env.example`) to a runtime `.env` file.
- Spins up the core Dockhand orchestration container using the root `compose.yml`.
- Merges the root configuration with the target stack's overrides to launch the environment.

## Managing Stacks Locally
A Makefile is available at the root of the repository to standardize operations. You must specify the target stack directory using the STACK argument, or use the built-in convenience shortcuts.

### 1. Starting a Stack
To spin up Dockhand combined with a specific service layer, use the generic up command: `make up STACK=05-tools`
Alternatively, you can use the predefined stack shortcuts: 
```bash
make sso          # Starts Dockhand + SSO stack (01-sso)
make core         # Starts Dockhand + Core stack (02-core)
make multimedia   # Starts Dockhand + Multimedia stack (03-multimedia)
make downloads    # Starts Dockhand + Downloads stack (04-downloads)
make tools        # Starts Dockhand + Tools stack (05-tools)
make monitoring   # Starts Dockhand + Monitoring stack (06-monitoring)
```
### 2. Stopping a Stack
To safely tear down an active stack along with the base Dockhand container, run: 
```bash
make down STACK=05-tools
```

### 3. Code Quality & Linting
Before committing changes to YAML configurations, run the built-in formatter to ensure syntax compliance. This executes yamlfix inside an isolated ephemeral Docker container, preventing the need for local Python dependencies:
```bash
make lint
```

### 4. Help CommandTo list all available automation targets and shortcuts, run:
```bash
make help
```