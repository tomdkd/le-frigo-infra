# LeFrigo Infrastructure Rules

This document describes the infrastructure design rules that govern the LeFrigo Docker Compose deployment.

## 1. Stack Separation
- Each logical stack is deployed from its own `*/compose.yml` file.
- Stacks are isolated by default and join only the networks they require.
- The root stack (`compose.yml`) provides the orchestrator and common socket proxies.
- Runtime environment variables are sourced from `STACK/stack.env.example` and copied to `STACK/.env` by the Makefile.

## 2. Network Conventions
- `lefrigo-net` is the shared application network used by most services.
- `authentik-net` is the dedicated internal network for Authentik core services.
- `docker-proxy-net` is a small root-level network used only by `docker-proxy` and `dockhand`.
- `01-sso_authentik-net` is an external bridge network used by the monitoring stack to connect into the SSO/system network boundary.
- `host` networking is reserved for `tailscale` to enable direct mesh VPN access.
- `network_mode: service:gluetun` is used by `qbittorrent` to force all torrent traffic through the VPN container.

## 3. Service Exposure Rules
- Traefik only discovers services that opt in with `traefik.enable=true`.
- All public-facing services must include explicit `Host(...)` routing rules and a `websecure` entrypoint.
- HTTP traffic is redirected to HTTPS at the Traefik level.
- Non-public backend services (databases, caches, workers, socket proxies) do not expose Traefik labels.
- Exposed services must specify `traefik.docker.network=lefrigo-net` when the container is attached to multiple networks.

## 4. Docker Socket Policy
- The host Docker socket is never mounted directly into internet-facing services.
- `tecnativa/docker-socket-proxy` is used to provide a limited Docker API surface to authorized containers.
- `dockhand` and `traefik` each use a dedicated socket proxy instance to separate control plane access.

## 5. Identity and Authentication
- Authentik is the single source of identity and access control for Traefik-proxied apps.
- Applications without native OIDC support are protected with Traefik ForwardAuth middleware.
- Applications with native OIDC (Outline, Mealie) are configured to authenticate directly against Authentik.

## 6. Persistence and Permissions
- Host directory binds are used for all persistent data to preserve TrueNAS dataset semantics.
- Containers run with unified `PUID` and `PGID` values to maintain consistent UID/GID ownership.
- Shared application data uses `${APPS_DATA_DIR}` and media content uses `${MEDIA_DATA_DIR}`.
- Secrets are injected through `.env` files and should not be committed into version control.
