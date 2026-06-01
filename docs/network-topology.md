# LeFrigo Network Topology

This document explains the major Docker network topologies and traffic flows inside LeFrigo.

## 1. Root Network Layers
- `docker-proxy-net`: Root-level management network used only by `docker-proxy` and `dockhand`.
- `lefrigo-net`: The primary application network where Traefik, core services, and most app containers communicate.

## 2. Auth Stack Topology
- `authentik-net`: Private Authentik network for `authentik-db`, `docker-proxy-authentik`, and core Authentik processes.
- `authentik-server` bridges `authentik-net` and `lefrigo-net` so Traefik can expose the Authentik UI and the Authentik outpost endpoint.

## 3. Monitoring Bridge
- `01-sso_authentik-net`: An external bridge network used by `databasus` from `06-monitoring`.
- This bridge enables secure cross-stack connectivity without exposing all monitoring services to the public network.

## 4. VPN / Download Routing
- `gluetun` is attached to `lefrigo-net` and receives a dedicated public-facing Traefik route for its web UI.
- `qbittorrent` uses `network_mode: service:gluetun`, meaning it does not join `lefrigo-net` directly.
- All traffic from `qbittorrent` exits through the WireGuard VPN managed by `gluetun`.

## 5. Host Network Services
- `tailscale` runs in `network_mode: host` to provide a full mesh VPN endpoint on the host network.
- This avoids container network isolation for Tailscale and allows direct access to the host interface.

## 6. Traefik Service Discovery and Routing
- Traefik listens on host ports `81` and `444`, mapped to container ports `80` and `443`.
- It discovers services via `docker-proxy-read` on `tcp://docker-proxy-read:2375`.
- Only services with explicit Traefik labels are published, reducing accidental exposure.

## 7. Internal Connectivity Summary
- `lefrigo-net` is the default shared network for app-to-app communication.
- Services with multiple networks use explicit routing labels to keep public and private traffic separate.
- Database and cache services remain internal unless they must be reachable by a proxied app.
