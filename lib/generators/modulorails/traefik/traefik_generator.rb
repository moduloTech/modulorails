# frozen_string_literal: true

require 'rails/generators'
require 'fileutils'

class Modulorails::TraefikGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)

  desc 'This generator sets up the global Traefik infrastructure and utility scripts'

  class_option :traefik_dir, type: :string, default: '~/traefik',
               desc: 'Directory to install Traefik infrastructure'
  class_option :scripts_dir, type: :string, default: '~/.local/bin',
               desc: 'Directory to install utility scripts'

  def create_traefik_infrastructure
    traefik_dir = File.expand_path(options[:traefik_dir])

    say "Creating Traefik infrastructure in #{traefik_dir}...", :green

    FileUtils.mkdir_p(traefik_dir)

    create_file "#{traefik_dir}/docker-compose.yml", traefik_compose_content
    create_file "#{traefik_dir}/README.md", traefik_readme_content
  end

  def create_utility_scripts
    scripts_dir = File.expand_path(options[:scripts_dir])

    say "Creating utility scripts in #{scripts_dir}...", :green

    FileUtils.mkdir_p(scripts_dir)

    create_file "#{scripts_dir}/rails-dev", rails_dev_script_content
    create_file "#{scripts_dir}/rails-stop", rails_stop_script_content
    create_file "#{scripts_dir}/rails-list", rails_list_script_content

    chmod "#{scripts_dir}/rails-dev", 0o755
    chmod "#{scripts_dir}/rails-stop", 0o755
    chmod "#{scripts_dir}/rails-list", 0o755
  end

  def create_docker_networks
    say 'Creating Docker networks...', :green

    system('docker network create traefik-proxy 2>/dev/null || true')
    system('docker network create development 2>/dev/null || true')
  end

  def print_instructions
    traefik_dir = File.expand_path(options[:traefik_dir])
    scripts_dir = File.expand_path(options[:scripts_dir])

    say ''
    say '=' * 60, :green
    say 'Traefik infrastructure has been set up!', :green
    say '=' * 60, :green
    say ''
    say 'Next steps:', :yellow
    say ''
    say "1. Ensure #{scripts_dir} is in your PATH:", :cyan
    say "   echo 'export PATH=\"#{scripts_dir}:$PATH\"' >> ~/.zshrc"
    say '   source ~/.zshrc'
    say ''
    say '2. Configure dnsmasq for .localhost domains (macOS):', :cyan
    say '   brew install dnsmasq'
    say "   echo 'address=/.localhost/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf"
    say '   sudo brew services start dnsmasq'
    say '   sudo mkdir -p /etc/resolver'
    say '   echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/localhost'
    say ''
    say '3. Start Traefik:', :cyan
    say "   cd #{traefik_dir} && docker compose up -d"
    say ''
    say 'Access:', :yellow
    say '  - Traefik Dashboard: http://traefik.localhost'
    say '  - Your apps: http://{project-name}.localhost'
    say '  - Mailcatcher: http://mail.{project-name}.localhost'
    say ''
  end

  private

  def traefik_compose_content
    <<~YAML
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
    YAML
  end

  def traefik_readme_content
    <<~MARKDOWN
      # Infrastructure Traefik pour projets Rails

      Cette infrastructure permet d'exécuter plusieurs projets Rails simultanément sans conflit de ports.

      ## Démarrage

      ```bash
      docker compose up -d
      ```

      ## Accès

      - **Dashboard Traefik**: http://traefik.localhost
      - **Applications Rails**: http://{nom-projet}.localhost
      - **Mailcatcher**: http://mail.{nom-projet}.localhost

      ## Vérification

      ```bash
      # Vérifier que Traefik est en cours d'exécution
      docker ps | grep traefik

      # Vérifier les réseaux Docker
      docker network ls | grep -E "traefik-proxy|development"
      ```

      ## Arrêt

      ```bash
      docker compose down
      ```

      ## Scripts utilitaires

      Les scripts suivants sont disponibles dans `~/.local/bin`:

      - `rails-dev` : Démarre un projet Rails (vérifie et démarre Traefik si nécessaire)
      - `rails-stop` : Arrête un projet Rails
      - `rails-list` : Liste tous les projets Rails actifs

      ## Dépannage

      ### Traefik ne démarre pas

      Vérifiez qu'aucun autre service n'utilise le port 80:
      ```bash
      sudo lsof -i :80
      ```

      ### Les domaines .localhost ne fonctionnent pas

      Assurez-vous que dnsmasq est configuré:
      ```bash
      # macOS
      brew install dnsmasq
      echo 'address=/.localhost/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf
      sudo brew services start dnsmasq
      sudo mkdir -p /etc/resolver
      echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/localhost
      ```

      ### Un projet n'est pas accessible

      Vérifiez que le projet utilise les bons labels Traefik:
      ```bash
      docker inspect <container_name> | grep -A 20 Labels
      ```
    MARKDOWN
  end

  def rails_dev_script_content
    <<~BASH
      #!/bin/bash

      PROJECT_NAME=$(basename "$PWD")

      # Vérifier que Traefik tourne
      if ! docker ps | grep -q traefik; then
          echo "⚠️  Traefik n'est pas démarré. Démarrage..."
          (cd ~/traefik && docker compose up -d)
          sleep 2
      fi

      # Créer les réseaux si nécessaire
      docker network create traefik-proxy 2>/dev/null || true
      docker network create development 2>/dev/null || true

      # Définir le nom du projet
      export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

      # Démarrer selon le type de projet
      if [ -d ".devcontainer" ]; then
          echo "🚀 Démarrage du devcontainer pour $PROJECT_NAME..."

          # Créer le fichier .env si nécessaire
          if [ ! -f ".devcontainer/.env" ]; then
              echo "COMPOSE_PROJECT_NAME=$PROJECT_NAME" > .devcontainer/.env
          fi

          # Ouvrir dans VS Code avec le devcontainer
          if command -v code &> /dev/null; then
              code --folder-uri "vscode-remote://dev-container+$(printf '%s' "$PWD" | xxd -plain | tr -d '\\n')/rails"
          else
              echo "VS Code n'est pas installé. Démarrage manuel..."
              docker compose -f .devcontainer/compose.yml up -d
          fi
      else
          echo "🚀 Démarrage de Docker Compose pour $PROJECT_NAME..."
          docker compose up -d
      fi

      echo ""
      echo "✅ $PROJECT_NAME est accessible via :"
      echo "   🌐 Application : http://$PROJECT_NAME.localhost"
      echo "   📧 Mailcatcher : http://mail.$PROJECT_NAME.localhost"
      echo ""
      echo "📊 Dashboard Traefik : http://traefik.localhost"
    BASH
  end

  def rails_stop_script_content
    <<~BASH
      #!/bin/bash

      PROJECT_NAME=$(basename "$PWD")
      export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

      if [ -d ".devcontainer" ]; then
          echo "🛑 Arrêt du devcontainer $PROJECT_NAME..."
          docker compose -f .devcontainer/compose.yml down
      else
          echo "🛑 Arrêt de $PROJECT_NAME..."
          docker compose down
      fi

      echo "✅ $PROJECT_NAME arrêté."
    BASH
  end

  def rails_list_script_content
    <<~BASH
      #!/bin/bash

      echo "📋 Projets Rails actifs :"
      echo ""

      # Récupérer tous les conteneurs avec traefik.enable=true
      containers=$(docker ps --filter "label=traefik.enable=true" --format "{{.Names}}" 2>/dev/null)

      if [ -z "$containers" ]; then
          echo "  Aucun projet actif."
      else
          for container in $containers; do
              # Extraire le nom du projet depuis le nom du conteneur
              # Format typique: project-name-app-1 ou project-name-service-1
              project=$(echo "$container" | sed -E 's/^(.+)-(app|web|sidekiq|mailcatcher|js|css|webpack)-[0-9]+$/\\1/')

              # Récupérer l'URL depuis les labels
              url=$(docker inspect "$container" --format '{{range $k, $v := .Config.Labels}}{{if eq $k "traefik.http.routers.'$project'-app.rule"}}{{$v}}{{end}}{{end}}' 2>/dev/null | sed "s/Host(\`\\(.*\\)\`)/\\1/")

              if [ -n "$url" ]; then
                  echo "  🟢 $project → http://$url"
              else
                  echo "  🟢 $container"
              fi
          done
      fi

      echo ""
      echo "📊 Dashboard Traefik : http://traefik.localhost"
    BASH
  end

end
