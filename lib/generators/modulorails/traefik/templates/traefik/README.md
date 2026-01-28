# Infrastructure Traefik pour projets Rails

## Prerequis

### macOS (avec Homebrew)

```bash
brew install dnsmasq
echo 'address=/.localhost/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf
sudo brew services start dnsmasq
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/localhost
```

### Linux

Ajouter dans `/etc/hosts` ou configurer dnsmasq selon votre distribution.

## Demarrage

```bash
docker compose up -d
```

## Acces

- Dashboard Traefik : http://traefik.localhost

## Verification

```bash
# Verifier que Traefik tourne
docker ps | grep traefik

# Verifier les reseaux
docker network ls | grep -E "traefik-proxy|development"
```

## Arret

```bash
docker compose down
```

## URLs des projets

Chaque projet Rails sera accessible via :
- Application : `http://{nom_projet}.localhost`
- Mailcatcher : `http://mail.{nom_projet}.localhost`
- MinIO Console : `http://minio.{nom_projet}.localhost`
- MinIO API : `http://s3.{nom_projet}.localhost`

## Depannage

### Le dashboard n'est pas accessible

1. Verifier que Traefik tourne :
   ```bash
   docker ps | grep traefik
   ```

2. Verifier les logs :
   ```bash
   docker logs traefik
   ```

3. Verifier la resolution DNS :
   ```bash
   ping traefik.localhost
   ```

### Les projets ne sont pas accessibles

1. Verifier que le projet est connecte aux bons reseaux :
   ```bash
   docker network inspect traefik-proxy
   ```

2. Verifier les labels Traefik sur les containers :
   ```bash
   docker inspect <container_name> | grep -A 20 Labels
   ```
