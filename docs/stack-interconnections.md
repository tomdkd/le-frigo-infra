# LeFrigo Stack Interconnections

This document describes how each logical stack connects with others and which shared resources are used.

## 1. Root Orchestration
- `compose.yml` defines the base stack with:
  - `docker-proxy`: safe Docker API proxy
  - `dockhand`: runtime orchestrator for stack composition
- Root services are attached to `docker-proxy-net` and `lefrigo-net`.

## 2. 01-sso (Identity Provider)
- Provides Authentik SSO, database, and an isolated socket proxy.
- `authentik-server` is the only Authentik service connected to `lefrigo-net`, allowing Traefik to publish the portal.
- `authentik-worker` uses both `authentik-net` and `lefrigo-net` to access the database and shared application network.

## 3. 02-core (Core Infrastructure)
- Hosts Traefik, the shared PostgreSQL instance, Redis, and a core Docker socket proxy.
- `traefik` is the ingress gateway for all stacks.
- `postgres-common` supports `outline`, `mealie`, and other tools.
- `redis` is the shared cache for OIDC-aware applications and internal services.

## 4. 03-multimedia (Media Services)
- Relies on `traefik` for public routing on `lefrigo-net`.
- Contains `jellyfin`, `immich-server`, `immich-db`, `audiobookshelf`, `gonic`, and `vibrdrome-web`.
- Uses host-mounted media directories under `${MEDIA_DATA_DIR}`.

## 5. 04-downloads (Acquisition Pipeline)
- `gluetun` provides WireGuard VPN routing for download traffic.
- `qbittorrent` is sandboxed inside `gluetun` and does not join `lefrigo-net` directly.
- `prowlarr`, `radarr`, `sonarr`, `lidarr`, `ygege`, `shelfmark`, and `metube` operate on `lefrigo-net` and connect through Traefik where exposed.
- `radarr`, `sonarr`, and `lidarr` all rely on index and metadata services for automation.

## 6. 05-tools (Productivity)
- Hosts `outline`, `mealie`, `jellyseerr`, `homeassistant`, `code-server`, `whodb`, `filebrowser`, and `picard`.
- `outline` uses `postgres-common` and `redis` from `02-core`.
- `mealie` uses native Authentik OIDC integration for authentication.
- `homeassistant`, `jellyseerr`, `filebrowser`, and `picard` are protected by Traefik and Authentik when routed publicly.
- `whodb` is connected to both `lefrigo-net` and `01-sso_authentik-net`.

## 7. 06-monitoring (Observability & Backup)
- Contains `uptime-kuma`, `backrest`, `tailscale`, `databasus`, and `vaultwarden`.
- `backrest` has broad volume access for backup targets and is protected behind Authentik.
- `tailscale` runs in host networking mode to provide mesh VPN access.
- `databasus` connects to both `lefrigo-net` and `01-sso_authentik-net` for cross-stack observability.
- `vaultwarden` is exposed through Traefik and protected with ForwardAuth.

## 8. Cross-stack Dependencies
- `traefik` is the shared ingress point for every stack that exposes a UI or API.
- `authentik` is the centralized identity provider for edge access.
- Shared storage directories under `${APPS_DATA_DIR}` and `${MEDIA_DATA_DIR}` are reused by multiple stacks.
- External networks and explicit service labels determine which cross-stack connections are permitted.
