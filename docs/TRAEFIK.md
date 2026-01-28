# Configuration Traefik pour projets Rails

Cette documentation décrit l'intégration de Traefik comme reverse proxy pour les projets Rails générés par Modulorails.

## Vue d'ensemble

Traefik permet d'exécuter plusieurs projets Rails simultanément sans conflit de ports. Chaque projet est accessible via un sous-domaine `.localhost` dédié :

- Application : `http://{projet}.localhost`
- Mailcatcher : `http://mail.{projet}.localhost`

## Prérequis

### 1. Configuration DNS (macOS)

Installez et configurez dnsmasq pour résoudre les domaines `.localhost` :

```bash
# Installation
brew install dnsmasq

# Configuration
echo 'address=/.localhost/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf

# Démarrage du service
sudo brew services start dnsmasq

# Configuration du resolver
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/localhost
```

### 2. Configuration DNS (Linux)

Sur Linux, vous pouvez utiliser systemd-resolved ou modifier `/etc/hosts` :

```bash
# Option 1: Ajouter dans /etc/hosts (pour chaque projet)
echo "127.0.0.1 mon-projet.localhost mail.mon-projet.localhost" | sudo tee -a /etc/hosts

# Option 2: Utiliser dnsmasq
sudo apt install dnsmasq
echo 'address=/.localhost/127.0.0.1' | sudo tee /etc/dnsmasq.d/localhost.conf
sudo systemctl restart dnsmasq
```

### 3. Installation de l'infrastructure Traefik

Exécutez le générateur Traefik pour installer l'infrastructure globale :

```bash
rails generate modulorails:traefik
```

Ce générateur crée :
- `~/traefik/docker-compose.yml` : Configuration Traefik
- `~/.local/bin/rails-dev` : Script pour démarrer un projet
- `~/.local/bin/rails-stop` : Script pour arrêter un projet
- `~/.local/bin/rails-list` : Script pour lister les projets actifs

### 4. Ajout des scripts au PATH

Assurez-vous que `~/.local/bin` est dans votre PATH :

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 5. Démarrage de Traefik

```bash
cd ~/traefik && docker compose up -d
```

## Utilisation

### Démarrer un projet

```bash
cd mon-projet
rails-dev
```

Ce script :
1. Vérifie que Traefik est démarré (le démarre sinon)
2. Crée les réseaux Docker nécessaires
3. Démarre le projet (devcontainer ou docker-compose)
4. Affiche les URLs d'accès

### Arrêter un projet

```bash
cd mon-projet
rails-stop
```

### Lister les projets actifs

```bash
rails-list
```

## Nouveaux projets

Les nouveaux projets générés par Modulorails incluent automatiquement la configuration Traefik. Aucune action supplémentaire n'est nécessaire.

## Migration de projets existants

Pour migrer un projet existant vers Traefik :

```bash
./bin/migrate_to_traefik /chemin/vers/projet
```

Ce script :
1. Crée un backup de la configuration existante
2. Crée le fichier `.env` avec `COMPOSE_PROJECT_NAME`
3. Affiche les modifications manuelles à effectuer

### Modifications manuelles requises

#### Dans `compose.yml` ou `docker-compose.yml`

1. **Ajouter les réseaux** en fin de fichier :

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

2. **Modifier le service `app`** :

```yaml
services:
  app:
    # ... configuration existante ...
    networks:
      - default
      - development
      - traefik-proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-app.rule=Host(`${COMPOSE_PROJECT_NAME}.localhost`)"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-app.entrypoints=web"
      - "traefik.http.services.${COMPOSE_PROJECT_NAME}-app.loadbalancer.server.port=3000"
    # Supprimer: ports: ["3000:3000"]
```

3. **Modifier les services internes** (`database`, `redis`) :

```yaml
  database:
    # ... configuration existante ...
    networks:
      - default
    # Supprimer: expose ou ports
```

4. **Modifier `mailcatcher`** :

```yaml
  mailcatcher:
    # ... configuration existante ...
    networks:
      - default
      - traefik-proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-mail.rule=Host(`mail.${COMPOSE_PROJECT_NAME}.localhost`)"
      - "traefik.http.routers.${COMPOSE_PROJECT_NAME}-mail.entrypoints=web"
      - "traefik.http.services.${COMPOSE_PROJECT_NAME}-mail.loadbalancer.server.port=1080"
    # Supprimer: expose ou ports
```

#### Dans `devcontainer.json` (si applicable)

```json
{
  "name": "${localEnv:COMPOSE_PROJECT_NAME:nom-projet}",
  "forwardPorts": [],
  "remoteEnv": {
    "COMPOSE_PROJECT_NAME": "${localEnv:COMPOSE_PROJECT_NAME:nom-projet}"
  }
}
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Navigateur                                │
│                                                                  │
│   http://projet-a.localhost    http://projet-b.localhost        │
│              │                          │                        │
└──────────────┼──────────────────────────┼────────────────────────┘
               │                          │
               ▼                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Traefik                                  │
│                     (Port 80)                                   │
│                                                                  │
│   - Route par Host header                                        │
│   - Dashboard: http://traefik.localhost                         │
└─────────────────────────────────────────────────────────────────┘
               │                          │
               │  traefik-proxy           │  traefik-proxy
               │  network                 │  network
               ▼                          ▼
┌──────────────────────────┐ ┌──────────────────────────┐
│      Projet A            │ │      Projet B            │
│                          │ │                          │
│ ┌──────────────────────┐ │ │ ┌──────────────────────┐ │
│ │   App (Port 3000)    │ │ │ │   App (Port 3000)    │ │
│ └──────────────────────┘ │ │ └──────────────────────┘ │
│ ┌──────────────────────┐ │ │ ┌──────────────────────┐ │
│ │   Database           │ │ │ │   Database           │ │
│ └──────────────────────┘ │ │ └──────────────────────┘ │
│ ┌──────────────────────┐ │ │ ┌──────────────────────┐ │
│ │   Redis              │ │ │ │   Redis              │ │
│ └──────────────────────┘ │ │ └──────────────────────┘ │
│ ┌──────────────────────┐ │ │ ┌──────────────────────┐ │
│ │   Mailcatcher        │ │ │ │   Mailcatcher        │ │
│ └──────────────────────┘ │ │ └──────────────────────┘ │
│                          │ │                          │
│   development network    │ │   development network    │
└──────────────────────────┘ └──────────────────────────┘
```

## Réseaux Docker

- **traefik-proxy** : Connecte Traefik aux services exposés (app, mailcatcher)
- **development** : Permet la communication entre projets si nécessaire
- **default** : Réseau interne du projet (database, redis)

## Variables d'environnement

| Variable | Description | Exemple |
|----------|-------------|---------|
| `COMPOSE_PROJECT_NAME` | Nom du projet (utilisé pour les routes Traefik) | `mon-projet` |

## Dépannage

### Traefik ne démarre pas

Vérifiez qu'aucun autre service n'utilise le port 80 :

```bash
sudo lsof -i :80
```

### Les domaines .localhost ne fonctionnent pas

1. Vérifiez que dnsmasq est actif :
   ```bash
   sudo brew services list | grep dnsmasq
   ```

2. Testez la résolution DNS :
   ```bash
   nslookup test.localhost 127.0.0.1
   ```

### Un projet n'est pas accessible

1. Vérifiez que le conteneur est sur le réseau traefik-proxy :
   ```bash
   docker network inspect traefik-proxy
   ```

2. Vérifiez les labels Traefik :
   ```bash
   docker inspect <container_name> | grep -A 20 Labels
   ```

3. Consultez les logs Traefik :
   ```bash
   docker logs traefik
   ```

### Erreur "network not found"

Créez les réseaux manuellement :

```bash
docker network create traefik-proxy
docker network create development
```

## Référence des URLs

| Service | URL |
|---------|-----|
| Application | `http://{projet}.localhost` |
| Mailcatcher | `http://mail.{projet}.localhost` |
| Dashboard Traefik | `http://traefik.localhost` |
