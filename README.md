# Modulorails [![Build Status](https://travis-ci.com/Ezveus/modulorails.svg?branch=master)](https://travis-ci.com/Ezveus/modulorails)

**Modulorails** is the common base for the Ruby on Rails project at [Modulotech](https://www.modulotech.fr/).

It registers each application using it on the company's intranet,
provides templates for the common configurations and defines common dependencies.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'modulorails'
```

And then execute:

    $ bundle install

## Usage

To work the gem needs to be configured. Add an initializer `config/modulorails.rb`:

```ruby
Modulorails.configure do |config|
  config.name 'The usual name of the application'
  config.main_developer 'The email of the main developer/maintainer of the application'
  config.project_manager 'The email of the project manager of the application'
  config.endpoint 'The url to the intranet'
  config.api_key 'The API key'
  config.review_base_url 'The base url for the review environments' # optional
  config.staging_url 'The url for the staging environment'          # optional
  config.production_url 'The url for the production environment'    # optional
end
``` 

## Traefik Integration

Modulorails now supports Traefik as a reverse proxy, allowing multiple Rails projects to run simultaneously without port conflicts.

### Quick Setup

1. Configure dnsmasq for `.localhost` domains (macOS):
   ```bash
   brew install dnsmasq
   echo 'address=/.localhost/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf
   sudo brew services start dnsmasq
   sudo mkdir -p /etc/resolver
   echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/localhost
   ```

2. Create Docker network:
   ```bash
   docker network create traefik-proxy
   ```

3. Start Traefik (see [docs/TRAEFIK.md](docs/TRAEFIK.md) for the docker-compose.yml):
   ```bash
   cd ~/traefik && docker compose up -d
   ```

### Using Traefik

```bash
# Start a project
cd my-project
docker compose -f .devcontainer/compose.yml up -d

# Access the application
open http://my-project.localhost

# Access Mailcatcher
open http://mail.my-project.localhost
```

### Migrating Existing Projects

```bash
./bin/migrate_to_traefik /path/to/existing/project
```

For detailed documentation, see [docs/TRAEFIK.md](docs/TRAEFIK.md).

## Development

There are tests in `spec`. To run tests:
- Build Docker images using `docker compose build`.
- You can run tests on all supported Ruby versions using `docker compose up`.
- Or you can run test on a specific Ruby version using one of the following commands:
  - Ruby 2.5: `docker compose run ruby25`
  - Ruby 2.6: `docker compose run ruby26`
  - Ruby 2.7: `docker compose run ruby27`
  - Ruby 3.0: `docker compose run ruby30`
  - Ruby 3.1: `docker compose run ruby31`

[Appraisal](https://github.com/thoughtbot/appraisal) is used to test the gem against many supported Rails versions:
  - Rails 5.2, 6.0 and 6.1 on Ruby 2.5 and 2.6. 
  - Rails 5.2, 6.0, 6.1 and 7.0 on Ruby 2.7, 3.0 and 3.1. 

Travis CI is configured to automatically run tests in all supported Ruby versions and dependency sets after each push.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/moduloTech/modulorails](https://github.com/moduloTech/modulorails). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/moduloTech/modulorails/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Modulorails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/moduloTech/modulorails/blob/master/CODE_OF_CONDUCT.md).
