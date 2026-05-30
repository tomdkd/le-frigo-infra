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
- `authentik-worker` uses `authentik-net` and `lefrigo-net` to access the database and shared application network.

## 3. 02-core (Core Infrastructure)
- Hosts Traefik, the shared PostgreSQL instance, Redis, and a Docker socket proxy.
- `traefik` is the ingress gateway for all stacks.
- `postgres-common` supports `outline` and `mealie` and can also be used by additional stacks.
- `redis` is the shared cache for OIDC-aware applications and internal tools.

## 4. 03-multimedia (Media Services)
- Relies on `traefik` for public routing on `lefrigo-net`.
- Contains `jellyfin`, `navidrome`, `immich`, and `audiobookshelf`.
- Uses host-mounted media directories under `${MEDIA_DATA_DIR}`.

## 5. 04-downloads (Acquisition Pipeline)
- `gluetun` provides WireGuard VPN routing for download traffic.
- `qbittorrent` is sandboxed inside `gluetun` and never joins the shared app network directly.
- `prowlarr`, `radarr`, `sonarr`, `ygege`, and `shelfmark` operate on `lefrigo-net` and are exposed through Traefik.
- `radarr` and `sonarr` depend on `prowlarr` for index management.

## 6. 05-tools (Productivity)
- Hosts `outline`, `mealie`, `jellyseerr`, `homeassistant`, `code-server`, and `whodb`.
- `outline` uses `postgres-common` and `redis` from `02-core`.
- `mealie` uses native Authentik OIDC integration to authenticate users.
- `homeassistant` and `jellyseerr` are protected by Traefik and Authentik when exposed.

## 7. 06-monitoring (Observability & Backup)
- Contains `uptime-kuma`, `backrest`, `tailscale`, `databasus`, and `vaultwarden`.
- `backrest` has broad volume access for backup targets and is protected behind Authentik.
- `tailscale` runs on the host network to provide remote mesh access.
- `databasus` is attached to both `lefrigo-net` and `01-sso_authentik-net`.
- `vaultwarden` is exposed through Traefik and protected with ForwardAuth.

## 8. Cross-stack Dependencies
- `traefik` is the shared ingress point for every stack that exposes a UI or API.
- `authentik` is the centralized identity provider for edge security.
- Shared storage directories under `${APPS_DATA_DIR}` and `${MEDIA_DATA_DIR}` are reused by multiple stacks.
- External networks and service labels determine which cross-stack connections are permitted.
