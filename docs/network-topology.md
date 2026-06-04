# LeFrigo Network Topology

This document explains the major Docker network topologies and traffic flows inside LeFrigo.

## 1. Root Network Layers
- `docker-proxy-net`: Root-level management network for the root stack’s `docker-proxy` and `dockhand`.
- `lefrigo-net`: Shared application network used by Traefik and most container workloads.
- `core-docker-proxy`: Core stack network used by Traefik’s Docker socket proxy.
- `monitoring-docker-proxy`: Monitoring stack network used by that stack’s Docker socket proxy.

## 2. Auth Stack Topology
- `authentik-net`: Private Authentik network for `authentik-db`, `docker-proxy-authentik`, `authentik-worker`, and `authentik-server`.
- `authentik-server` bridges `authentik-net` and `lefrigo-net` so Traefik can expose the Authentik UI and outpost endpoint.

## 3. Monitoring Bridge
- `01-sso_authentik-net`: External bridge network used by cross-stack services such as `databasus`.
- This bridge enables secure cross-stack monitoring without exposing all monitoring services directly to the public network.

## 4. VPN / Download Routing
- `gluetun` is attached to `lefrigo-net` and receives a dedicated public-facing Traefik route for its web UI.
- `qbittorrent` uses `network_mode: service:gluetun`, so it does not join `lefrigo-net` directly.
- All traffic from `qbittorrent` exits through the WireGuard VPN managed by `gluetun`.

## 5. Host Network Services
- `tailscale` runs in `network_mode: host` to provide a full mesh VPN endpoint on the host interface.
- Direct host networking avoids container network isolation for Tailscale and allows mesh access to host services.

## 6. Traefik Service Discovery and Routing
- Traefik listens on host ports `81` and `444`, mapped to container ports `80` and `443`.
- It discovers services via the core stack’s Docker proxy at `tcp://docker-proxy:2375`.
- Only services with explicit Traefik labels are published to reduce accidental exposure.

## 7. Internal Connectivity Summary
- `lefrigo-net` is the default shared network for app-to-app communication.
- Services attached to multiple networks must use explicit labels to separate public and private traffic.
- Database and cache services remain internal unless they need to be reachable by a proxied application.
