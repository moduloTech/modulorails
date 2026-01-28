# frozen_string_literal: true

require 'rails/generators'

module Modulorails

  class TraefikGenerator < Rails::Generators::Base

    source_root File.expand_path('templates', __dir__)

    desc 'This generator sets up Traefik infrastructure for multi-project development'

    class_option :traefik_dir, type: :string, default: '~/traefik',
                 desc: 'Directory to install Traefik infrastructure'
    class_option :scripts_dir, type: :string, default: '~/.local/bin',
                 desc: 'Directory to install utility scripts'
    class_option :skip_scripts, type: :boolean, default: false,
                 desc: 'Skip installing utility scripts'
    class_option :skip_traefik, type: :boolean, default: false,
                 desc: 'Skip installing Traefik infrastructure'

    def create_traefik_infrastructure
      return if options[:skip_traefik]

      traefik_dir = File.expand_path(options[:traefik_dir])
      FileUtils.mkdir_p(traefik_dir)

      template 'traefik/docker-compose.yml', File.join(traefik_dir, 'docker-compose.yml')
      template 'traefik/README.md', File.join(traefik_dir, 'README.md')

      say_status :create, "Traefik infrastructure in #{traefik_dir}", :green
    end

    def create_utility_scripts
      return if options[:skip_scripts]

      scripts_dir = File.expand_path(options[:scripts_dir])
      FileUtils.mkdir_p(scripts_dir)

      %w[rails-dev rails-stop rails-list].each do |script|
        script_path = File.join(scripts_dir, script)
        template "scripts/#{script}", script_path
        chmod script_path, 0o755
      end

      say_status :create, "Utility scripts in #{scripts_dir}", :green
    end

    def create_docker_networks
      say 'Creating Docker networks...'

      system('docker network create traefik-proxy 2>/dev/null') || true
      system('docker network create development 2>/dev/null') || true

      say_status :create, 'Docker networks (traefik-proxy, development)', :green
    end

    def print_post_install_instructions
      traefik_dir = File.expand_path(options[:traefik_dir])
      scripts_dir = File.expand_path(options[:scripts_dir])

      say ''
      say '=' * 60
      say 'Traefik Integration Setup Complete!'
      say '=' * 60
      say ''
      say 'Next steps:'
      say ''
      say '1. Ensure dnsmasq is configured for .localhost domains:'
      say '   brew install dnsmasq'
      say "   echo 'address=/.localhost/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf"
      say '   sudo brew services start dnsmasq'
      say '   sudo mkdir -p /etc/resolver'
      say '   echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/localhost'
      say ''
      say '2. Start Traefik:'
      say "   cd #{traefik_dir} && docker compose up -d"
      say ''
      say '3. Ensure scripts are in your PATH:'
      say "   export PATH=\"#{scripts_dir}:$PATH\""
      say ''
      say '4. Access Traefik dashboard at: http://traefik.localhost'
      say ''
      say '=' * 60
    end

  end

end
