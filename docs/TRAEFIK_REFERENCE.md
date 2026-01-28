# Reference Traefik pour Modulorails

Ce document fournit une reference complete de l'integration Traefik dans Modulorails.

## Architecture

```
                    +-------------------+
                    |     Navigateur    |
                    +-------------------+
                            |
                            v
                    +-------------------+
                    |   Traefik :80     |
                    | traefik.localhost |
                    +-------------------+
                            |
        +-------------------+-------------------+
        |                   |                   |
        v                   v                   v
+---------------+   +---------------+   +---------------+
|   Projet A    |   |   Projet B    |   |   Projet C    |
| a.localhost   |   | b.localhost   |   | c.localhost   |
+---------------+   +---------------+   +---------------+
```

## Reseaux Docker

### traefik-proxy
Reseau pour la communication entre Traefik et les services exposes.

```bash
docker network create traefik-proxy
```

### development
Reseau pour la communication inter-projets (si necessaire).

```bash
docker network create development
```

## Configuration Traefik

### docker-compose.yml (~/traefik/)

```yaml
services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=traefik-proxy"
      - "--entrypoints.web.address=:80"
      - "--log.level=INFO"
      - "--accesslog=true"
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - traefik-proxy
      - development
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(`traefik.localhost`)"
      - "traefik.http.routers.dashboard.service=api@internal"

networks:
  traefik-proxy:
    name: traefik-proxy
  development:
    name: development
```

## Labels Traefik

### Service web (Rails)

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-app.rule=Host(`${COMPOSE_PROJECT_NAME}.localhost`)"
  - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-app.entrypoints=web"
  - "traefik.http.services.${COMPOSE_PROJECT_NAME}-app.loadbalancer.server.port=3000"
```

### Mailcatcher

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-mail.rule=Host(`mail.${COMPOSE_PROJECT_NAME}.localhost`)"
  - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-mail.entrypoints=web"
  - "traefik.http.services.${COMPOSE_PROJECT_NAME}-mail.loadbalancer.server.port=1080"
```

### MinIO Console

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-minio-console.rule=Host(`minio.${COMPOSE_PROJECT_NAME}.localhost`)"
  - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-minio-console.entrypoints=web"
  - "traefik.http.services.${COMPOSE_PROJECT_NAME}-minio-console.loadbalancer.server.port=9001"
```

### MinIO API

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-minio-api.rule=Host(`s3.${COMPOSE_PROJECT_NAME}.localhost`)"
  - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-minio-api.entrypoints=web"
  - "traefik.http.services.${COMPOSE_PROJECT_NAME}-minio-api.loadbalancer.server.port=9000"
```

## URLs des services

| Service | URL |
|---------|-----|
| Application Rails | `http://{projet}.localhost` |
| Mailcatcher | `http://mail.{projet}.localhost` |
| MinIO Console | `http://minio.{projet}.localhost` |
| MinIO API | `http://s3.{projet}.localhost` |
| Dashboard Traefik | `http://traefik.localhost` |

## Variables d'environnement

### COMPOSE_PROJECT_NAME

Variable utilisee pour identifier uniquement chaque projet.

```bash
# .env
COMPOSE_PROJECT_NAME=mon_projet
```

Cette variable est utilisee dans :
- Les URLs Traefik
- Les noms de bases de donnees
- Les noms de routers Traefik

## Scripts utilitaires

### rails-dev

Demarre un projet Rails avec Traefik.

```bash
cd /chemin/vers/projet
rails-dev
```

Fonctionnalites :
- Verifie et demarre Traefik si necessaire
- Cree les reseaux Docker
- Detecte le type de projet (devcontainer ou docker-compose)
- Affiche les URLs d'acces

### rails-stop

Arrete un projet Rails.

```bash
cd /chemin/vers/projet
rails-stop
```

### rails-list

Liste les projets Rails actifs.

```bash
rails-list
```

## Generateurs

### modulorails:traefik

Installe l'infrastructure Traefik globale.

```bash
rails generate modulorails:traefik [options]
```

Options :
- `--traefik-dir=DIR` : Repertoire Traefik (defaut: ~/traefik)
- `--scripts-dir=DIR` : Repertoire des scripts (defaut: ~/.local/bin)
- `--skip-scripts` : Ne pas installer les scripts
- `--skip-traefik` : Ne pas installer Traefik

### modulorails:traefik_migration

Migre un projet existant vers Traefik.

```bash
rails generate modulorails:traefik_migration [options]
```

Options :
- `--no-backup` : Ne pas creer de backup

### modulorails:devcontainer

Genere la configuration devcontainer avec Traefik.

```bash
rails generate modulorails:devcontainer
```

## Configuration DNS

### macOS avec dnsmasq

```bash
# Installation
brew install dnsmasq

# Configuration
echo 'address=/.localhost/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf

# Demarrage
sudo brew services start dnsmasq

# Resolver
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/localhost
```

### Verification

```bash
# Tester la resolution
ping test.localhost

# Doit repondre 127.0.0.1
```

## Depannage

### Traefik ne demarre pas

```bash
# Verifier les logs
docker logs traefik

# Verifier le port 80
lsof -i :80
```

### Service non accessible

```bash
# Verifier que le service est connecte au reseau traefik-proxy
docker network inspect traefik-proxy

# Verifier les labels
docker inspect <container> | jq '.[0].Config.Labels'

# Verifier les routers Traefik
curl http://localhost:8080/api/http/routers | jq
```

### Resolution DNS echouee

```bash
# macOS - Verifier dnsmasq
brew services list | grep dnsmasq

# Verifier le resolver
cat /etc/resolver/localhost

# Forcer le flush DNS
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### Conflits de noms de projets

Si deux projets ont le meme nom, modifiez `COMPOSE_PROJECT_NAME` dans le fichier `.env` de l'un des projets.

```bash
# Projet 1
COMPOSE_PROJECT_NAME=projet-v1

# Projet 2
COMPOSE_PROJECT_NAME=projet-v2
```

## Bonnes pratiques

1. **Nommage des projets** : Utilisez des noms uniques et courts (alphanumeriques et tirets)

2. **Demarrage de Traefik** : Demarrez Traefik avant les projets

3. **Arret propre** : Utilisez `rails-stop` pour arreter les projets

4. **Backup** : Gardez les backups de migration jusqu'a validation complete

5. **Variables d'environnement** : Ne commitez pas le fichier `.env` avec des valeurs sensibles

## Compatibilite

- Docker : 20.10+
- Docker Compose : v2.0+
- Traefik : v3.0
- macOS : 11+ (avec dnsmasq)
- Linux : toutes distributions avec Docker
