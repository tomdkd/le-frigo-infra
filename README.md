# LeFrigo Infrastructure

LeFrigo is a modular self-hosted Docker Compose homelab for TrueNAS SCALE and Linux hosts. It organizes services into isolated logical stacks and centralizes edge routing through Traefik with Authentik identity.

## Stacks
- `01-sso` — Authentik identity provider and isolated socket proxy
- `02-core` — Traefik ingress, shared PostgreSQL, and Redis
- `03-multimedia` — Jellyfin, Navidrome, Immich, Audiobookshelf
- `04-downloads` — Gluetun, qBittorrent, Prowlarr, Radarr, Sonarr, Ygege, Shelfmark
- `05-tools` — Outline, Mealie, Home Assistant, code-server, Jellyseerr, WHODB
- `06-monitoring` — Uptime Kuma, Backrest, Tailscale, Databasus, Vaultwarden

## Quick start
Start a stack from the repository root:
```bash
make up STACK=05-tools
```

Stop a stack:
```bash
make down STACK=05-tools
```

Show available targets:
```bash
make help
```

## Notes
- Each stack contains a `stack.env.example`; use the Makefile to generate `STACK/.env`.
- The root `compose.yml` provides the Dockhand orchestrator and the Docker socket proxy.
- For architecture and topology details, see `.ai-agent/infrastructure.md` and the `docs/` directory.
