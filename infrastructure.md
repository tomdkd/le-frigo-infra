# Infrastructure V2

## 1. Architecture réseau & flux 🌐

### 1.1 Réseaux Docker déclarés

| Réseau | Stack | Type | External | Rôle opérationnel |
|---|---|---|---|---|
| docker-proxy-net | racine | bridge local | non | Réseau de gestion pour le proxy Docker de la stack racine et le service Dockhand. |
| lefrigo-net | racine / data-hub / system | bridge local | oui pour data-hub, non pour les autres | Réseau partagé de bout en bout pour les services applicatifs et l’ingress Traefik. |
| data-hub-net | data-hub | bridge local | non | Réseau privé supplémentaire utilisé par Jellyfin. |
| data-hub-db-net | data-hub | bridge local | non | Réseau dédié aux bases de données de la pile media. |
| data-hub-redis-net | data-hub | bridge local | non | Réseau dédié à Redis et aux services Immich associés. |
| traefik-proxy-net | system | bridge local | non | Réseau de communication entre Traefik et le proxy Docker socket. |
| lldap-db-net | system | bridge local | non | Réseau isolé entre PostgreSQL et LLDAP. |
| lldap-auth-net | system | bridge local | non | Réseau isolé entre LLdap et Tinyauth. |

### 1.2 Flux réseau principal

1. Un client accède au service via les ports hôte 81/444 du nœud, exposés par Traefik dans la stack system.
2. Traefik écoute sur les ports 80/443, applique les règles de routage définies par labels et contacte le service cible via le réseau lefrigo-net.
3. Les services de la stack data-hub utilisent des labels Traefik pour être exposés publiquement, avec routage HTTPS et certification ACME via le resolver myresolver.
4. Les services internes (bases de données, caches, proxy Docker socket) ne sont pas exposés publiquement et restent limités à leur réseau interne.
5. qBittorrent n’utilise pas de réseau séparé : il est lancé avec network_mode: service:gluetun, ce qui force tout son trafic à passer par le conteneur Gluetun et donc à sortir via le tunnel VPN WireGuard.

### 1.3 Cheminement type d’une requête

- Requête HTTP vers un service proxied :
  - client -> hôte:81/444
  - Traefik (stack system) -> détection de labels -> résolution du service cible
  - service cible sur le réseau lefrigo-net -> réponse au client via Traefik
- Requête vers une application de la stack data-hub sans label Traefik :
  - accessible uniquement en interne, sur son réseau dédié ou le réseau partagé
  - non exposée au monde extérieur

---

## 2. Cartographie exhaustive des stacks 📦

### 2.1 Stack racine : orchestrateur et proxy Docker

Rôle : fournir l’orchestrateur Dockhand et un proxy Docker socket pour la gestion des stacks applicatives.

#### Services

##### docker-proxy
- Image : tecnativa/docker-socket-proxy
- Container name : docker-proxy
- Restart policy : non définie (pas de restart explicite)
- Réseaux : docker-proxy-net
- Ports : aucun port publié
- Labels : aucun
- Volumes : /var/run/docker.sock:/var/run/docker.sock:ro
- Dépendances : aucune
- Notes techniques : expose un sous-ensemble limité du Docker API via des variables d’environnement (CONTAINERS, IMAGES, NETWORKS, VOLUMES, POST, AUTH, INFO, EVENTS, PORT).

##### dockhand
- Image : fnsys/dockhand:latest
- Container name : dockhand
- Restart policy : non définie
- Réseaux : docker-proxy-net, lefrigo-net
- Ports : 1000:3000
- Labels : aucun
- Volumes : ./data/dockhand:/app/data
- Dépendances : aucune
- Notes techniques : service d’orchestration exposé sur le port hôte 1000.

---

### 2.2 Stack data-hub : médias, téléchargement, automatisation et streaming

Rôle : fournir la pile media et téléchargement : bases de données, VPN, téléchargements, indexation, streaming, photos et audio.

#### Services

##### postgres-media
- Image : postgres:16-alpine
- Container name : postgres-media
- Restart policy : unless-stopped
- Réseaux : data-hub-db-net
- Ports : aucun port publié
- Labels : aucun
- Volumes : ${APPS_DATA_DIR}/postgres-media:/var/lib/postgresql/data
- Dépendances : aucune
- Notes techniques : base PostgreSQL pour Immich ; healthcheck via pg_isready.

##### redis-media
- Image : redis:8.6.1
- Container name : redis-media
- Restart policy : always
- Réseaux : data-hub-redis-net
- Ports : aucun port publié
- Labels : aucun
- Volumes : aucun
- Dépendances : aucune
- Notes techniques : cache Redis utilisé par Immich ; healthcheck via redis-cli ping.

##### gluetun
- Image : qmcgaw/gluetun:pr-3361
- Container name : gluetun
- Restart policy : always
- Réseaux : lefrigo-net
- Ports : 8080:8080, 8001:8000
- Labels :
  - traefik.enable=true
  - traefik.http.routers.torrent.rule=Host(`torrent.le-frigo.fr`)
  - traefik.http.routers.torrent.service=torrent
  - traefik.http.routers.torrent.entrypoints=websecure
  - traefik.http.routers.torrent.tls.certresolver=myresolver
  - traefik.http.routers.torrent.middlewares=tinyauth@docker
  - traefik.http.services.torrent.loadbalancer.server.port=8080
  - tinyauth.apps.torrent.ldap.groups=admin
- Volumes : aucun
- Dépendances : aucune
- Notes techniques : exécute WireGuard via des capacités NET_ADMIN et un device /dev/net/tun ; healthcheck HTTPS vers Google.

##### qbittorrent
- Image : lscr.io/linuxserver/qbittorrent:5.2.1
- Container name : qbittorrent
- Restart policy : always
- Réseaux : aucun réseau explicite ; utilise network_mode: service:gluetun
- Ports : aucun port publié séparément
- Labels : aucun
- Volumes :
  - ${APPS_DATA_DIR}/qbitorrent/config:/config
  - ${MEDIA_DATA_DIR}:/data
- Dépendances : gluetun (condition service_healthy)
- Notes techniques : trafic forcé via le conteneur Gluetun.

##### qbitwebui
- Image : ghcr.io/mkbula/qbitwebui:latest
- Container name : non défini
- Restart policy : unless-stopped
- Réseaux : réseau Compose implicite (aucun réseau explicite)
- Ports : 8081:3000
- Labels :
  - traefik.enable=true
  - traefik.http.routers.qbitwebui.rule=Host(`torrent.le-frigo.fr`)
  - traefik.http.routers.qbitwebui.service=qbitwebui
  - traefik.http.routers.qbitwebui.entrypoints=websecure
  - traefik.http.routers.qbitwebui.tls.certresolver=myresolver
  - traefik.http.services.qbitwebui.loadbalancer.server.port=3000
  - traefik.http.routers.qbitwebui.middlewares=tinyauth@docker
  - tinyauth.apps.qbitwebui.ldap.groups=admin
- Volumes :
  - ${APPS_DATA_DIR}/qbitwebui/data:/data
  - ${MEDIA_DATA_DIR}/downloads:/downloads:ro
- Dépendances : aucune

##### prowlarr
- Image : lscr.io/linuxserver/prowlarr:2.4.0-nightly
- Container name : prowlarr
- Restart policy : always
- Réseaux : lefrigo-net
- Ports : 9696:9696
- Labels : aucun
- Volumes : ${APPS_DATA_DIR}/prowlarr:/config
- Dépendances : gluetun (condition service_healthy)
- Notes techniques : healthcheck HTTP local sur /.

##### radarr
- Image : lscr.io/linuxserver/radarr:6.2.1-nightly
- Container name : radarr
- Restart policy : always
- Réseaux : lefrigo-net
- Ports : 7878:7878
- Labels :
  - traefik.enable=true
  - traefik.http.routers.radarr.rule=Host(`radarr.le-frigo.fr`)
  - traefik.http.routers.radarr.service=radarr
  - traefik.http.routers.radarr.entrypoints=websecure
  - traefik.http.routers.radarr.tls.certresolver=myresolver
  - traefik.http.routers.radarr.middlewares=tinyauth@docker
  - traefik.http.services.radarr.loadbalancer.server.port=7878
  - tinyauth.apps.radarr.ldap.groups=admin
- Volumes :
  - ${APPS_DATA_DIR}/radarr:/config
  - ${MEDIA_DATA_DIR}:/data
- Dépendances : prowlarr (condition service_healthy)

##### sonarr
- Image : lscr.io/linuxserver/sonarr:4.0.17
- Container name : sonarr
- Restart policy : always
- Réseaux : lefrigo-net
- Ports : 8989:8989
- Labels :
  - traefik.enable=true
  - traefik.http.routers.sonarr.rule=Host(`sonarr.le-frigo.fr`)
  - traefik.http.routers.sonarr.service=sonarr
  - traefik.http.routers.sonarr.entrypoints=websecure
  - traefik.http.routers.sonarr.tls.certresolver=myresolver
  - traefik.http.routers.sonarr.middlewares=tinyauth@docker
  - traefik.http.services.sonarr.loadbalancer.server.port=8989
  - tinyauth.apps.sonarr.ldap.groups=admin
- Volumes :
  - ${APPS_DATA_DIR}/sonarr:/config
  - ${MEDIA_DATA_DIR}:/data
- Dépendances : prowlarr (condition service_healthy)

##### ygege
- Image : uwucode/ygege:0.9.1
- Container name : ygege
- Restart policy : unless-stopped
- Réseaux : lefrigo-net
- Ports : 8715:8715
- Labels : aucune
- Volumes : aucune
- Dépendances : gluetun et prowlarr (conditions service_healthy)

##### metube
- Image : alexta69/metube:2026.06.06
- Container name : metube
- Restart policy : unless-stopped
- Réseaux : lefrigo-net
- Ports : 8086:8081
- Labels :
  - traefik.enable=true
  - traefik.http.routers.metube.rule=Host(`metube.le-frigo.fr`)
  - traefik.http.routers.metube.service=metube
  - traefik.http.routers.metube.entrypoints=websecure
  - traefik.http.routers.metube.tls.certresolver=myresolver
  - traefik.http.services.metube.loadbalancer.server.port=8081
  - traefik.http.routers.metube.middlewares=tinyauth@docker
  - tinyauth.apps.metube.ldap.groups=admin
- Volumes : ${MEDIA_DATA_DIR}/youtube_downloads:/downloads
- Dépendances : aucune

##### jellyfin
- Image : jellyfin/jellyfin:10.11.11
- Container name : jellyfin
- Restart policy : unless-stopped
- Réseaux : lefrigo-net, data-hub-net
- Ports : 8096:8096/tcp, 7359:7359/udp
- Labels :
  - traefik.enable=true
  - traefik.http.routers.jellyfin.rule=Host(`jellyfin.le-frigo.fr`)
  - traefik.http.routers.jellyfin.entrypoints=websecure
  - traefik.http.routers.jellyfin.tls=true
  - traefik.http.routers.jellyfin.tls.certresolver=myresolver
  - traefik.http.services.jellyfin.loadbalancer.server.port=8096
  - traefik.http.routers.jellyfin.middlewares=error-pages-middleware@docker
  - traefik.docker.network=lefrigo-net
  - tinyauth.apps.jellyfin.ldap.groups=user,admin
- Volumes :
  - ${APPS_DATA_DIR}/jellyfin:/config
  - ${MEDIA_DATA_DIR}/films:/films
  - ${MEDIA_DATA_DIR}/series:/series
  - ${MEDIA_DATA_DIR}/stuck_in_yesterday:/stuck_in_yesterday
- Dépendances : aucune

##### immich-server
- Image : ghcr.io/immich-app/immich-server:commit-dc2c01e4737eb6524d1d4a16ee47ffac16264111
- Container name : immich_server
- Restart policy : non définie
- Réseaux : lefrigo-net, data-hub-db-net, data-hub-redis-net
- Ports : 2283:2283
- Labels :
  - traefik.enable=true
  - traefik.http.routers.immich.service=immich
  - traefik.http.routers.immich.rule=Host(`immich.le-frigo.fr`)
  - traefik.http.routers.immich.entrypoints=websecure
  - traefik.http.routers.immich.tls.certresolver=myresolver
  - traefik.http.services.immich.loadbalancer.server.port=2283
- Volumes :
  - ${MEDIA_DATA_DIR}/photos:/data
  - /etc/localtime:/etc/localtime:ro
- Dépendances : postgres-media et redis-media (conditions service_healthy)

##### audiobookshelf
- Image : ghcr.io/advplyr/audiobookshelf:2.35.1
- Container name : audiobookshelf
- Restart policy : always
- Réseaux : lefrigo-net
- Ports : 8085:80
- Labels :
  - traefik.enable=true
  - traefik.http.routers.audiobookshelf.service=audiobookshelf
  - traefik.http.routers.audiobookshelf.rule=Host(`audiobooks.le-frigo.fr`)
  - traefik.http.routers.audiobookshelf.entrypoints=websecure
  - traefik.http.routers.audiobookshelf.tls.certresolver=myresolver
  - traefik.http.services.audiobookshelf.loadbalancer.server.port=80
  - tinyauth.apps.audiobookshelf.ldap.groups=user,admin
- Volumes :
  - ${APPS_DATA_DIR}/audiobookshelf/config:/config
  - ${APPS_DATA_DIR}/audiobookshelf/metadata:/metadata
  - ${MEDIA_DATA_DIR}/books:/data
- Dépendances : aucune

##### gonic
- Image : sentriz/gonic:v0.22.0
- Container name : gonic
- Restart policy : unless-stopped
- Réseaux : lefrigo-net
- Ports : 4747:80
- Labels :
  - traefik.enable=true
  - traefik.http.routers.gonic-api.rule=Host(`music.api.le-frigo.fr`)
  - traefik.http.routers.gonic-api.entrypoints=websecure
  - traefik.http.routers.gonic-api.tls=true
  - traefik.http.routers.gonic-api.tls.certresolver=myresolver
  - traefik.http.routers.gonic-api.service=gonic-svc
  - traefik.http.routers.gonic-api.middlewares=gonic-cors
  - traefik.http.services.gonic-svc.loadbalancer.server.port=80
  - traefik.http.middlewares.gonic-cors.headers.accesscontrolallowmethods=GET,OPTIONS,POST
  - traefik.http.middlewares.gonic-cors.headers.accesscontrolalloworiginlist=https://music.le-frigo.fr
  - traefik.http.middlewares.gonic-cors.headers.accesscontrolallowheaders=*
  - tinyauth.apps.gonic.ldap.groups=user,admin
- Volumes :
  - ${APPS_DATA_DIR}/gonic/data:/data
  - ${MEDIA_DATA_DIR}/musique:/music:ro
  - ${APPS_DATA_DIR}/gonic/playlists:/playlists
  - ${APPS_DATA_DIR}/gonic/cache:/cache
  - ${APPS_DATA_DIR}/gonic/podcasts:/podcasts
- Dépendances : aucune
- Notes techniques : security_opt no-new-privileges:true.

##### vibrdrome-web
- Image : ddmoney420/vibrdrome-web:v1.8.1-beta.2
- Container name : vibrdrome-web
- Restart policy : unless-stopped
- Réseaux : lefrigo-net
- Ports : 8009:80
- Labels :
  - traefik.enable=true
  - traefik.http.routers.vibrdrome.rule=Host(`music.le-frigo.fr`)
  - traefik.http.routers.vibrdrome.entrypoints=websecure
  - traefik.http.routers.vibrdrome.tls=true
  - traefik.http.routers.vibrdrome.tls.certresolver=myresolver
  - traefik.http.routers.vibrdrome.service=vibrdrome-svc
  - traefik.http.services.vibrdrome-svc.loadbalancer.server.port=80
  - traefik.http.routers.vibrdrome.middlewares=tinyauth@docker
  - tinyauth.apps.vibrdrome.ldap.groups=user,admin
- Volumes : aucun
- Dépendances : gonic

---

### 2.3 Stack system : ingress, auth et identité

Rôle : fournir Traefik comme point d’entrée unique, la couche d’authentification et l’authentification OAuth/LDAP.

#### Services

##### docker-proxy-traefik
- Image : ghcr.io/tecnativa/docker-socket-proxy:latest
- Container name : non défini
- Restart policy : unless-stopped
- Réseaux : traefik-proxy-net
- Ports : aucun port publié
- Labels : aucun
- Volumes : /var/run/docker.sock:/var/run/docker.sock:ro
- Dépendances : aucune

##### traefik
- Image : traefik:v3.6.9
- Container name : traefik
- Restart policy : unless-stopped
- Réseaux : lefrigo-net, traefik-proxy-net
- Ports : 81:80, 444:443
- Labels :
  - traefik.enable=true
  - traefik.http.routers.dashboard.rule=Host(`traefik.le-frigo.fr`)
  - traefik.http.routers.dashboard.service=api@internal
  - traefik.http.routers.dashboard.entrypoints=websecure
  - traefik.http.routers.dashboard.tls.certresolver=myresolver
  - traefik.http.routers.dashboard.middlewares=tinyauth@docker,error-pages-middleware
  - traefik.docker.network=lefrigo-net
- Volumes :
  - /etc/localtime:/etc/localtime:ro
  - ${APPS_DATA_DIR}/traefik/acme.json:/acme.json
- Dépendances : aucune
- Notes techniques : configuration CLI complète pour le provider Docker, les entrypoints web/websecure, les redirections HTTP vers HTTPS et ACME.

##### postgres-server
- Image : postgres:16-alpine
- Container name : non défini
- Restart policy : unless-stopped
- Réseaux : lldap-db-net
- Ports : aucun port publié
- Labels : aucun
- Volumes : ${APPS_DATA_DIR}/lldap/postgres:/var/lib/postgresql/data
- Dépendances : aucune

##### lldap
- Image : lldap/lldap:stable
- Container name : non défini
- Restart policy : unless-stopped
- Réseaux : lldap-db-net, lldap-auth-net
- Ports : 1000:17170
- Labels : aucune
- Volumes : ${APPS_DATA_DIR}/lldap/data:/data
- Dépendances : postgres-server (condition service_healthy)

##### tinyauth
- Image : ghcr.io/steveiliop56/tinyauth:v5
- Container name : non défini
- Restart policy : unless-stopped
- Réseaux : lefrigo-net, lldap-auth-net
- Ports : aucun port publié
- Labels :
  - traefik.enable=true
  - traefik.http.routers.tinyauth.rule=Host(`login.le-frigo.fr`)
  - traefik.http.routers.tinyauth.entrypoints=websecure
  - traefik.http.routers.tinyauth.tls=true
  - traefik.http.services.tinyauth.loadbalancer.server.port=3000
  - traefik.http.middlewares.tinyauth.forwardauth.address=http://tinyauth:3000/api/auth/traefik
  - traefik.http.routers.tinyauth.tls.certresolver=myresolver
  - traefik.docker.network=lefrigo-net
  - traefik.http.routers.tinyauth.middlewares=error-pages-middleware@docker
- Volumes : aucune
- Dépendances : lldap (condition service_healthy)
- Notes techniques : joue le rôle de forward-auth middleware et intègre LDAP et Pocket ID OAuth.

##### pocketid
- Image : ghcr.io/pocket-id/pocket-id:v2
- Container name : non défini
- Restart policy : unless-stopped
- Réseaux : lefrigo-net
- Ports : aucun port publié
- Labels :
  - traefik.enable=true
  - traefik.http.routers.pocketid.rule=Host(`pocketid.le-frigo.fr`)
  - traefik.http.routers.pocketid.entrypoints=websecure
  - traefik.http.routers.pocketid.tls.certresolver=myresolver
  - traefik.http.services.pocketid.loadbalancer.server.port=1411
  - traefik.docker.network=lefrigo-net
  - traefik.http.routers.pocketid.middlewares=error-pages-middleware@docker
- Volumes : ${APPS_DATA_DIR}/pocketid:/app/data
- Dépendances : tinyauth (condition service_healthy)

##### error-pages
- Image : ghcr.io/tarampampam/error-pages:4
- Container name : non défini
- Restart policy : non définie
- Réseaux : lefrigo-net
- Ports : aucun port publié
- Labels :
  - traefik.enable=true
  - traefik.http.routers.error-pages-router.rule=HostRegexp(`.+`)
  - traefik.http.routers.error-pages-router.priority=10
  - traefik.http.routers.error-pages-router.entrypoints=websecure
  - traefik.http.middlewares.error-pages-middleware.errors.status=400-599
  - traefik.http.middlewares.error-pages-middleware.errors.service=error-pages-service
  - traefik.http.middlewares.error-pages-middleware.errors.query=/{status}
  - traefik.http.services.error-pages-service.loadbalancer.server.port=8080
- Volumes : aucune
- Dépendances : traefik (condition service_healthy)

---

## 3. Configuration & variables 🔒

### 3.1 Variables de la stack data-hub

| Variable | Rôle |
|---|---|
| APPS_DATA_DIR | Répertoire hôte pour les données persistantes des applications. |
| MEDIA_DATA_DIR | Répertoire hôte pour le contenu multimédia et les téléchargements. |
| PUID | UID utilisateur à appliquer aux services qui exposent un utilisateur. |
| PGID | GID utilisateur à appliquer aux services qui exposent un groupe. |
| MEDIA_POSTGRES_USER | Nom d’utilisateur de la base PostgreSQL Immich. |
| MEDIA_POSTGRES_PASSWORD | Mot de passe de la base PostgreSQL Immich. |
| VPN_PROVIDER | Fournisseur VPN utilisé par Gluetun. |
| VPN_WG_PRIVATE_KEY | Clé privée WireGuard de Gluetun. |
| VPN_WG_ADDRESS | Adresse IP WireGuard assignée à Gluetun. |
| OPENVPN_USER | Identifiant VPN OpenVPN si utilisé par le fournisseur. |
| OPENVPN_PASSWORD | Mot de passe VPN OpenVPN si utilisé par le fournisseur. |

### 3.2 Variables de la stack system

| Variable | Rôle |
|---|---|
| APPS_DATA_DIR | Répertoire hôte pour les données persistantes de Traefik, LLdap, Pocket ID et autres services. |
| MEDIA_DATA_DIR | Répertoire hôte pour les médias si un service de cette stack en dépend. |
| PUID | UID applicatif utilisé par les services qui l’exigent. |
| PGID | GID applicatif utilisé par les services qui l’exigent. |
| LLDAP_JWT_SECRET | Secret JWT utilisé par LLdap. |
| LLDAP_KEY_SEED | Seed de chiffrement utilisé par LLdap. |
| LLDAP_ADMIN_PASSWORD | Mot de passe administrateur de LLdap, attendu par le compose ; l’exemple fournit LLDAP_ADMIN_PASSWORD_PLAIN et doit être aligné. |
| LDAP_POSTGRES_USER | Nom d’utilisateur PostgreSQL pour la base LLdap. |
| LDAP_POSTGRES_PASSWORD | Mot de passe PostgreSQL pour la base LLdap. |
| POCKETID_ENCRYPTION_KEY | Clé de chiffrement du service Pocket ID. |
| POCKETID_CLIENT_ID | Identifiant client Pocket ID pour Tinyauth. |
| POCKETID_CLIENT_SECRET | Secret client Pocket ID pour Tinyauth. |
| TINYAUTH_OIDC_CLIENTS_HOMARR_CLIENTID | Identifiant OIDC du client Homarr pour Tinyauth. |
| TINYAUTH_OIDC_CLIENTS_HOMARR_CLIENTSECRET | Secret OIDC du client Homarr pour Tinyauth. |

### 3.3 Traitement des secrets

- L’ensemble des secrets sensibles est injecté par des variables d’environnement à partir de fichiers .env locaux.
- Les valeurs ne doivent pas être commitées dans le dépôt.
- Les fichiers fournis sont des exemples de configuration et doivent être copiés vers un .env réel avant déploiement.

---

## 4. Maintenance & cycle de vie 🛠️

### 4.1 Stack racine

Démarrer :
```bash
docker compose -f compose.yml up -d
```

Arrêter :
```bash
docker compose -f compose.yml down
```

Vérifier les logs :
```bash
docker compose -f compose.yml logs -f
```

### 4.2 Stack data-hub

Préparer l’environnement :
```bash
cp data-hub/stack.env.example data-hub/.env
```

Démarrer :
```bash
docker compose -f compose.yml -f data-hub/compose.yml --env-file data-hub/.env up -d
```

Arrêter :
```bash
docker compose -f compose.yml -f data-hub/compose.yml --env-file data-hub/.env down
```

Vérifier les logs :
```bash
docker compose -f compose.yml -f data-hub/compose.yml --env-file data-hub/.env logs -f
```

### 4.3 Stack system

Préparer l’environnement :
```bash
cp system/stack.env.example system/.env
```

Démarrer :
```bash
docker compose -f compose.yml -f system/compose.yml --env-file system/.env up -d
```

Arrêter :
```bash
docker compose -f compose.yml -f system/compose.yml --env-file system/.env down
```

Vérifier les logs :
```bash
docker compose -f compose.yml -f system/compose.yml --env-file system/.env logs -f
```

### 4.4 Vérifications utiles

- État des conteneurs :
```bash
docker compose -f compose.yml -f system/compose.yml --env-file system/.env ps
```
- Vérification d’un service spécifique :
```bash
docker compose -f compose.yml -f data-hub/compose.yml --env-file data-hub/.env ps gluetun
```
- Reconstruction d’un service après modification de configuration :
```bash
docker compose -f compose.yml -f system/compose.yml --env-file system/.env up -d --force-recreate traefik
```
