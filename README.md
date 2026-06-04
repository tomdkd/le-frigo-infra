# LeFrigo Infrastructure

LeFrigo is a modular Docker Compose homelab designed for TrueNAS SCALE and Linux hosts. It organizes services into isolated logical stacks with a shared Traefik ingress layer and Authentik identity provider.

## Stacks
- `01-sso` — Authentik identity provider
- `02-core` — Traefik ingress, shared PostgreSQL, Redis
- `03-multimedia` — Jellyfin, Immich, Audiobookshelf, Navidrome, Gonic, Vibrdrome
- `04-downloads` — Gluetun VPN, qBittorrent, Prowlarr, Radarr, Sonarr, Lidarr, Ygege, Shelfmark, Metube
- `05-tools` — Outline, Mealie, Home Assistant, code-server, Jellyseerr, WHODB, File Browser, Picard
- `06-monitoring` — Uptime Kuma, Backrest, Tailscale, Databasus, Vaultwarden

## Quick start
Start one stack from the repository root:
```bash
make up STACK=05-tools
```

Stop the same stack:
```bash
make down STACK=05-tools
```

Show available targets:
```bash
make help
```

## Notes
- Each stack includes a `stack.env.example`; use the Makefile to generate `STACK/.env`.
- The root `compose.yml` defines the Dockhand orchestrator and host Docker socket proxy.
- For architecture and topology details, see `.ai-agent/infrastructure.md` and the `docs/` directory.
