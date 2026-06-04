# LeFrigo Infrastructure Source of Truth

This document serves as the definitive knowledge base for the LeFrigo self-hosted Docker infrastructure. It outlines the global architecture, individual deployment stacks, networks, and security policies.

## Reference Deep-Dive Docs
- `docs/infrastructure-rules.md`
- `docs/network-topology.md`
- `docs/stack-interconnections.md`

## 1. GLOBAL INFRASTRUCTURE OVERVIEW

### Architecture Style
LeFrigo follows a modular Docker Compose architecture optimized for TrueNAS SCALE and Linux hosts. A root `compose.yml` provides base orchestration and runtime service discovery, while each stack is defined in its own `STACK/compose.yml` file.

### Main Host Environment Traits
- **Host System:** TrueNAS SCALE or any Linux host with Docker Compose support.
- **Automation Engine:** `dockhand` coordinates root and stack-specific compose files.
- **Identity & Ingress:** Traefik v3 handles edge routing and SSL termination, with Authentik as the centralized identity provider.

### Storage & Volume Conventions
- Persistent state is stored through host bind mounts to preserve dataset semantics.
- **Execution Masks:** Containers use shared `PUID` and `PGID` values for consistent file ownership.
- **Key Paths:**
  - `${APPS_DATA_DIR}`: application configuration, databases, and service state.
  - `${MEDIA_DATA_DIR}`: media assets, downloads, and archive data.
  - `${SSH_DATA_DIR}`: SSH identity material for backup and remote access tools.

---

## 2. STACK BREAKDOWN

### Root Level (Orchestration & Base Management)
- **docker-proxy:** Limited Docker socket proxy for safe container metadata access.
- **dockhand:** Orchestrator container that starts base services and stack-specific compose groups.

### 01-sso (Identity Provider)
Handles Authentik SSO, worker processes, and a stack-specific Docker socket proxy.
- **authentik-db:** Dedicated PostgreSQL database for Authentik.
- **docker-proxy-authentik:** Isolated socket proxy for Authentik worker Docker access.
- **authentik-worker:** Asynchronous task processor.
- **authentik-server:** Main Authentik portal and edge authentication endpoint.

### 02-core (Technical Backbone)
Provides shared application infrastructure and ingress discovery.
- **traefik:** Edge reverse proxy managing HTTPS, ACME, and route discovery.
- **docker-proxy:** Socket proxy for Traefik service discovery.
- **postgres-common:** Shared PostgreSQL instance for apps such as Outline and Mealie.
- **redis:** Shared caching layer used by OIDC-aware applications.

### 03-multimedia (Entertainment & Archiving)
Media streaming and personal archive services.
- **jellyfin:** Video streaming server.
- **immich-server:** Photo management backend.
- **immich-db:** Dedicated PostgreSQL store for Immich.
- **audiobookshelf:** Audiobook and podcast streaming.
- **gonic:** Music server and API backend.
- **vibrdrome-web:** Browser frontend for game audio collection playback.

### 04-downloads (Media Acquisition Pipeline)
Automated acquisition and indexing services.
- **gluetun:** WireGuard VPN client and gateway.
- **qbittorrent:** Torrent client sandboxed within `gluetun`.
- **prowlarr:** Indexer management and search orchestration.
- **radarr:** Movie automation.
- **sonarr:** TV series automation.
- **lidarr:** Music download automation.
- **ygege:** Search and utility service.
- **shelfmark:** Ebook catalog and download tool.
- **metube:** YouTube download frontend.

### 05-tools (Productivity & Automation)
Collaboration, home automation, and developer utilities.
- **jellyseerr:** Media request manager.
- **outline:** Wiki workspace with Postgres and Authentik OIDC.
- **homeassistant:** Smart home automation platform.
- **mealie:** Recipe manager with Authentik OIDC.
- **code-server:** Web-based VS Code IDE.
- **whodb:** Lightweight database UI.
- **filebrowser:** File management UI.
- **picard:** Music tagging frontend.

### 06-monitoring (Observability & Backups)
Monitoring, backup orchestration, and secure remote access.
- **uptime-kuma:** Service health dashboard.
- **backrest:** Restic backup orchestrator.
- **tailscale:** Mesh VPN node using host networking.
- **databasus:** Database monitoring service attached to both `lefrigo-net` and `01-sso_authentik-net`.
- **vaultwarden:** Password manager protected by Authentik.

---

## 3. NETWORKING & ROUTING

### Network Topologies
- **docker-proxy-net:** Root-level management network for root stack services.
- **lefrigo-net:** Primary shared application network used by most services and by Traefik.
- **authentik-net:** Private Authentik network for Authentik internals.
- **core-docker-proxy:** Core stack network used by Traefik’s Docker proxy.
- **monitoring-docker-proxy:** Monitoring stack network used by the monitoring socket proxy.
- **01-sso_authentik-net:** External bridge network used by cross-stack services such as `databasus`.
- **Host networking:** Used only by `tailscale` to expose the mesh VPN directly on the host.

### Traefik Ingress
Traefik is the edge gateway. It is exposed on host ports `81` and `444` and proxies container ports `80` and `443`.
- **Service discovery:** Traefik queries the local socket proxy at `tcp://docker-proxy:2375`.
- **Opt-in exposure:** Only services with `traefik.enable=true` are published.
- **Certificate management:** ACME HTTP challenge via `myresolver`.
- **VPN-bound traffic:** `qbittorrent` runs inside `gluetun` and is isolated from the shared app network.

---

## 4. SECURITY & EXPOSURE POLICIES

### Access Control
- Edge access is centrally controlled by Authentik.
- Non-OIDC applications are protected with Traefik ForwardAuth.
- OIDC-native applications authenticate directly against Authentik.
- Public-facing routes require explicit Traefik labels.

### Sensitive Material
- Secrets and passwords are injected through `.env` files.
- Docker socket access is isolated through dedicated proxy containers.
- Persistent data is managed using host bind mounts and `PUID`/`PGID`.

### Isolation Principles
- Backend services remain internal on Docker bridge networks.
- Public routes are only available through Traefik.
- Direct socket or host port exposure is minimized.

---

## 5. REFERENCE DOCUMENTS
- `docs/infrastructure-rules.md`
- `docs/network-topology.md`
- `docs/stack-interconnections.md`
