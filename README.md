# LeFrigo Infrastructure

LeFrigo is a modular self-hosted Docker Compose homelab for TrueNAS SCALE. It splits infrastructure into isolated logical stacks, centralizes ingress through Traefik, and relies on Authentik for identity and access control.

## Stacks
- `01-sso` — Authentik identity provider, database, and isolated Docker socket proxy
- `02-core` — Traefik ingress, shared PostgreSQL, shared Redis, and Traefik Docker discovery proxy
- `03-multimedia` — Jellyfin, Navidrome, Immich, Audiobookshelf
- `04-downloads` — Gluetun VPN, qBittorrent, Prowlarr, Radarr, Sonarr, Ygege, Shelfmark
- `05-tools` — Outline, Mealie, Jellyseerr, Home Assistant, code-server, WHODB
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
- Each stack uses its own `stack.env.example` file to generate a runtime `STACK/.env`.
- The root `compose.yml` provides the Dockhand orchestrator and Docker socket proxies.
- Traefik is exposed on host ports `81` and `444`, mapped to container ports `80` and `443`.
- For deep architecture details, see `.ai-agent/infrastructure.md` and the `docs/` directory.
