# LeFrigo Infrastructure Rules

This document describes the infrastructure design rules that govern the LeFrigo Docker Compose deployment.

## 1. Stack Separation
- Each logical stack is deployed from its own `*/compose.yml` file.
- Stacks are isolated by default and only join the networks they require.
- The root stack (`compose.yml`) provides the orchestrator and the fundamental Docker socket proxy.
- Runtime environment variables are sourced from `STACK/stack.env.example` and copied to `STACK/.env` by the Makefile.

## 2. Network Conventions
- `lefrigo-net` is the shared application network used by most services.
- `authentik-net` is the private Authentik network for Authentik internals.
- `docker-proxy-net` is the root-level management network for the root stack’s socket proxy and orchestrator.
- `core-docker-proxy` is the core stack network used by Traefik’s Docker proxy.
- `monitoring-docker-proxy` is the monitoring stack network used by that stack’s Docker proxy.
- `01-sso_authentik-net` is an external bridge network used by cross-stack services such as `databasus`.
- `host` networking is reserved for `tailscale` to enable direct mesh VPN access.
- `network_mode: service:gluetun` is used by `qbittorrent` to force all torrent traffic through the VPN container.

## 3. Service Exposure Rules
- Traefik only discovers services that opt in with `traefik.enable=true`.
- All public-facing services must include explicit `Host(...)` routing rules and a `websecure` entrypoint.
- HTTP traffic is redirected to HTTPS at the Traefik level.
- Non-public backend services such as databases, caches, workers, and socket proxies must not expose Traefik labels unless they are intentionally routed.
- Services attached to multiple Docker networks must set `traefik.docker.network=lefrigo-net` to keep ingress routing consistent.

## 4. Docker Socket Policy
- The host Docker socket is not mounted directly into internet-facing services.
- `tecnativa/docker-socket-proxy` is used to provide a limited Docker API surface to authorized containers.
- The root stack, core stack, and monitoring stack each use separate socket proxy instances to isolate control plane access.

## 5. Identity and Authentication
- Authentik is the single source of identity and access control for Traefik-proxied apps.
- Applications without native OIDC support are protected with Traefik ForwardAuth middleware.
- Applications with native Authentik OIDC support (e.g. Outline, Mealie) authenticate directly via Authentik.

## 6. Persistence and Permissions
- Host directory binds are used for all persistent data to preserve TrueNAS dataset semantics.
- Containers use unified `PUID` and `PGID` values for consistent UID/GID ownership.
- Shared application data uses `${APPS_DATA_DIR}`; media content uses `${MEDIA_DATA_DIR}`.
- Secrets are injected through `.env` files and should not be committed to version control.
