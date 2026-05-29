# LeFrigo Infrastructure Source of Truth

This document serves as the definitive knowledge base for the LeFrigo self-hosted Docker infrastructure. It outlines the global architecture, individual deployment stacks, network routing, and security policies.

## 1. GLOBAL INFRASTRUCTURE OVERVIEW

### Architecture Style
LeFrigo follows a multi-stack, GitOps-driven architecture optimized for a TrueNAS SCALE host. It utilizes a modular Docker Compose deployment model managed by `Make` and orchestrated locally via a foundational container (`fnsys/dockhand`). The environment is segmented into discrete logical stacks to maintain isolation, separation of concerns, and ease of lifecycle management.

### Main Host Environment Traits
- **Host System:** TrueNAS SCALE (or similar Linux-based environment supporting Docker).
- **Automation Engine:** A custom orchestration layer (`Dockhand`) dynamically merges root configurations with target stack overrides during runtime using `.env` injections.
- **Identity & Ingress:** Traefik v3 serves as the ingress controller with SSL termination, tightly integrated with Authentik for centralized Identity and Access Management (IAM).

### Storage & Volume Conventions
- Data persistence strictly uses bind mounts to host directories to leverage TrueNAS dataset features.
- **Execution Masks:** Containers operate using unified `PUID` and `PGID` environmental variables to enforce strict file ownership across the host.
- **Key Directories:**
  - `${APPS_DATA_DIR}` (e.g., `/mnt/ssd-apps/apps` or `./apps`): Stores configuration and app-specific databases.
  - `${MEDIA_DATA_DIR}` (e.g., `/mnt/LeFrigo-Tank/data`): Stores raw multimedia files and downloads.
  - `${FOLDER_PATH}`: Common path mappings for utility scripts like database initialization.

---

## 2. STACK BREAKDOWN

The infrastructure is divided into the root orchestrator and 6 isolated stacks:

### Root Level (Orchestration & Base Management)
- **docker-proxy:** Socket proxy (`tecnativa/docker-socket-proxy`) for exposing safe Docker API events.
- **dockhand:** Orchestration container (`fnsys/dockhand`) mapping internal `.env` logic.
- **pgadmin:** UI management for PostgreSQL (`dpage/pgadmin4`), exposed on port 5050.

### 01-sso (Identity Provider)
Handles core identity management, SSO, and edge route authentication.
- **authentik-db:** Dedicated PostgreSQL 16 database for Authentik.
- **docker-proxy-authentik:** Isolated Docker socket proxy specifically for Authentik workers.
- **authentik-worker:** Background task processor for Authentik.
- **authentik-server:** Core IAM portal routing and processing OIDC/ForwardAuth requests.

### 02-core (Technical Backbone)
The foundational infrastructure enabling routing and central caching/databases.
- **traefik:** Edge reverse proxy routing external traffic to internal services and managing ACME Let's Encrypt certificates.
- **docker-proxy-read:** Read-only Docker socket proxy explicitly used by Traefik for service discovery.
- **postgres-common:** Central multi-tenant PostgreSQL 16 database serving downstream apps (e.g., Outline, Mealie).
- **common-redis:** Shared Redis in-memory cache for various applications.

### 03-multimedia (Entertainment & Archiving)
Platforms for streaming and managing media.
- **jellyfin:** Main media streaming platform (Movies, Series, Music).
- **navidrome:** Dedicated music streaming server.
- **immich-server:** High-performance photo management and backup system.
- **immich-db:** Specialized PostgreSQL (with `pgvector`) tailored for Immich.
- **audiobookshelf:** Podcast and audiobook streaming platform.

### 04-downloads (Media Acquisition Pipeline)
Automated media gathering and indexing utilities.
- **gluetun:** WireGuard VPN client encapsulating target containers (P2P routing).
- **qbittorrent:** Torrent client, fully sandboxed in Gluetun's network namespace (`network_mode: service:gluetun`).
- **prowlarr:** Indexer manager.
- **radarr:** Movie collection manager.
- **sonarr:** TV Series collection manager.
- **ygege:** Auxiliary search utility.
- **shelfmark:** E-book search and retrieval utility.

### 05-tools (Productivity & Automation)
Workspaces, recipe management, and smart home control.
- **jellyseerr:** Media request manager connecting users to Radarr/Sonarr.
- **outline:** Collaborative wiki workspace relying on Postgres, Redis, and OIDC.
- **homeassistant:** Smart home automation platform (runs privileged with host network elements).
- **mealie:** Recipe manager utilizing a dedicated Postgres DB and OIDC integration.
- **code-server:** Web-based VS Code IDE mapped to the deployment workspace.
- **whodb:** Lightweight database management UI.

### 06-monitoring (Observability & Backups)
Health checks, secure offsite access, and disaster recovery.
- **uptime-kuma:** Infrastructure health check and ping monitor.
- **backrest:** Privileged Restic backup orchestrator with deep host volume mounts.
- **tailscale:** Mesh VPN node running in `host` network mode for secure remote NAS access.
- **databasus:** Database tracking/monitoring tool.

---

## 3. NETWORKING & ROUTING

### Network Topologies
- **lefrigo-net:** The primary internal bridge network. Almost all services attach to this network to communicate with `traefik` and common databases/caches.
- **authentik-net:** Isolated network strictly for SSO components (Authentik DB, Worker, Server, and its dedicated docker proxy).
- **docker-proxy-net:** Small isolated network mapping the root docker socket proxy to the Dockhand orchestrator.

### Routing Logic (Traefik Ingress)
Traefik listens on HTTP (80/81) and HTTPS (443/444). Traffic is automatically redirected from HTTP to HTTPS.
- **Service Discovery:** Traefik dynamically discovers services by polling `docker-proxy-read` (tcp://docker-proxy-read:2375). Containers must explicitly opt-in with `traefik.enable=true`.
- **Certificates:** Uses Let's Encrypt HTTP challenges (`myresolver` ACME).
- **Load Balancing:** Explicitly defined ports (`loadbalancer.server.port`) are used when containers expose multiple ports.
- **Network Namespaces (VPN):** In stack `04-downloads`, `qbittorrent` has no native network interface. It shares the network stack of `gluetun` (Wireguard VPN). Traefik dynamically targets the `gluetun` container for `qbittorrent`'s web UI.

---

## 4. SECURITY & EXPOSURE POLICIES

### Access Control Rules & Authentication
LeFrigo implements a zero-trust model at the edge, leveraging Authentik for strict access control.
- **ForwardAuth Middleware:** Services that lack native authentication (e.g., Radarr, Sonarr, Uptime-Kuma, Backrest) are protected via Traefik middleware (`traefik.http.routers.<app>.middlewares=authentik@docker`). Unauthenticated requests are intercepted and redirected to the Authentik portal.
- **Native OIDC:** Modern apps (Outline, Mealie) use native OpenID Connect (OIDC) integration against Authentik's APIs.
- **Split Routing:** Certain apps like Navidrome utilize split routing:
  - The UI (`musique.le-frigo.fr` without `/rest`) is protected by Authentik ForwardAuth.
  - The API (`musique.le-frigo.fr` with `/rest`) remains open to allow native Subsonic clients to authenticate using their own token mechanics.

### Handling of Sensitive Data
- Passwords, API tokens, VPN configuration keys, OIDC secrets, and specific database credentials are not hardcoded. They are injected via `.env` files (e.g., `stack.env.example`) at runtime.
- Traefik stores its Let's Encrypt keys in a local locked `acme.json` file.
- The root docker socket (`/var/run/docker.sock`) is NEVER mounted directly into internet-facing applications (like Traefik). Instead, read-only subsets of the Docker API are exposed via the `tecnativa/docker-socket-proxy` proxies.

### Backend-For-Frontend (BFF) Pattern & Service Exposure
- **Exposed Services:** Containers configured with Traefik labels (`traefik.enable=true`) and matching host rules (e.g., `Host('*.le-frigo.fr')`) act as the frontend interface for users.
- **Hidden Services (Backends):** Databases (`postgres-common`, `authentik-db`, `immich-db`), caches (`redis`), workers (`authentik-worker`), and proxies (`docker-proxy-*`) NEVER expose their ports to the Traefik edge or external host interfaces unless explicitly debugged via safe local-only host port bindings (e.g., 5432:5432 for postgres). They rely entirely on isolated internal Docker bridge networking to communicate with frontend nodes.