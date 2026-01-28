# Guide de migration vers Traefik

Ce guide explique comment migrer un projet existant vers l'infrastructure Traefik pour permettre l'execution simultanee de plusieurs projets sans conflit de ports.

## Prerequis

### 1. Configuration DNS (dnsmasq)

#### macOS (avec Homebrew)

```bash
brew install dnsmasq
echo 'address=/.localhost/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf
sudo brew services start dnsmasq
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/localhost
```

#### Linux

Configurez dnsmasq selon votre distribution ou ajoutez manuellement les entrees dans `/etc/hosts`.

### 2. Installation de l'infrastructure Traefik

Executez le generateur Traefik pour installer l'infrastructure globale :

```bash
rails generate modulorails:traefik
```

Cela va creer :
- `~/traefik/docker-compose.yml` - Configuration Traefik
- `~/traefik/README.md` - Documentation
- `~/.local/bin/rails-dev` - Script de demarrage
- `~/.local/bin/rails-stop` - Script d'arret
- `~/.local/bin/rails-list` - Script de liste des projets actifs

### 3. Demarrage de Traefik

```bash
cd ~/traefik
docker compose up -d
```

Verifiez que le dashboard est accessible : http://traefik.localhost

## Pour les nouveaux projets

Les nouveaux projets generes avec Modulorails incluent automatiquement la configuration Traefik.

```bash
# Le docker-compose.yml genere inclut deja Traefik
rails generate modulorails:docker
```

## Pour les projets existants

### Migration automatique

Executez le generateur de migration :

```bash
rails generate modulorails:traefik_migration
```

Le generateur va :
1. Creer un backup de vos fichiers existants
2. Creer/mettre a jour le fichier `.env` avec `COMPOSE_PROJECT_NAME`
3. Creer les reseaux Docker necessaires
4. Migrer votre `compose.yml` ou `docker-compose.yml`
5. Migrer votre configuration devcontainer (si presente)

### Migration manuelle

Si vous preferez migrer manuellement, voici les modifications necessaires :

#### 1. Creer le fichier `.env`

```bash
COMPOSE_PROJECT_NAME=nom_du_projet
```

#### 2. Modifier `compose.yml` ou `docker-compose.yml`

**Ajouter les reseaux a la fin du fichier :**

```yaml
networks:
  development:
    external: true
    name: development
  traefik-proxy:
    external: true
    name: traefik-proxy
  default:
```

**Pour le service `app` :**

```yaml
services:
  app:
    # ... configuration existante ...
    # SUPPRIMER : ports: ["3000:3000"]
    networks:
      - default
      - development
      - traefik-proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-app.rule=Host(`${COMPOSE_PROJECT_NAME}.localhost`)"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-app.entrypoints=web"
      - "traefik.http.services.${COMPOSE_PROJECT_NAME}-app.loadbalancer.server.port=3000"
```

**Pour le service `database` :**

```yaml
  database:
    # ... configuration existante ...
    # SUPPRIMER : ports: ["5432:5432"] ou ["3306:3306"]
    networks:
      - default
```

**Pour le service `redis` :**

```yaml
  redis:
    # ... configuration existante ...
    networks:
      - default
```

**Pour le service `mailcatcher` :**

```yaml
  mailcatcher:
    # ... configuration existante ...
    # SUPPRIMER : ports: ["1080:1080", "1025:1025"]
    networks:
      - default
      - traefik-proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-mail.rule=Host(`mail.${COMPOSE_PROJECT_NAME}.localhost`)"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-mail.entrypoints=web"
      - "traefik.http.services.${COMPOSE_PROJECT_NAME}-mail.loadbalancer.server.port=1080"
```

**Pour le service `minio` (si present) :**

```yaml
  minio:
    # ... configuration existante ...
    # SUPPRIMER : ports: ["9000:9000", "9001:9001"]
    environment:
      # ... autres variables ...
      - MINIO_DOMAIN=s3.${COMPOSE_PROJECT_NAME}.localhost
      - MINIO_SERVER_URL=http://s3.${COMPOSE_PROJECT_NAME}.localhost
    networks:
      - default
      - traefik-proxy
    labels:
      - "traefik.enable=true"
      # Console MinIO
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-minio-console.rule=Host(`minio.${COMPOSE_PROJECT_NAME}.localhost`)"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-minio-console.entrypoints=web"
      - "traefik.http.services.${COMPOSE_PROJECT_NAME}-minio-console.loadbalancer.server.port=9001"
      # API MinIO
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-minio-api.rule=Host(`s3.${COMPOSE_PROJECT_NAME}.localhost`)"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-minio-api.entrypoints=web"
      - "traefik.http.services.${COMPOSE_PROJECT_NAME}-minio-api.loadbalancer.server.port=9000"
```

#### 3. Modifier `devcontainer.json` (si present)

```json
{
  "name": "${localEnv:COMPOSE_PROJECT_NAME:nom_projet}",
  "forwardPorts": [],
  "remoteEnv": {
    "COMPOSE_PROJECT_NAME": "${localEnv:COMPOSE_PROJECT_NAME:nom_projet}",
    // ... autres variables ...
  }
}
```

## Test de la migration

```bash
# Arreter les anciens containers
docker compose down

# Creer les reseaux
docker network create traefik-proxy 2>/dev/null || true
docker network create development 2>/dev/null || true

# Demarrer avec Traefik
rails-dev
```

Verifier l'acces :
- http://nom_projet.localhost

## Rollback

En cas de probleme, restaurez les fichiers depuis le backup :

```bash
cp .traefik-migration-backup-*/* .
# ou pour devcontainer
cp .traefik-migration-backup-*/* .devcontainer/
```

## Depannage

### L'application n'est pas accessible

1. Verifier que Traefik tourne :
   ```bash
   docker ps | grep traefik
   ```

2. Verifier les labels Traefik :
   ```bash
   docker inspect nom_projet-app-1 | grep -A 20 Labels
   ```

3. Verifier la resolution DNS :
   ```bash
   ping nom_projet.localhost
   ```

### Conflits de ports

Si vous avez toujours des conflits de ports, verifiez que vous avez bien supprime tous les `ports:` des services.

### Les reseaux n'existent pas

```bash
docker network create traefik-proxy
docker network create development
```
