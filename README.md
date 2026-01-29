# Modulorails

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
end
```

## Features

### Devcontainer Support

Modulorails automatically generates a `.devcontainer/` configuration for VS Code and compatible IDEs:
- `Dockerfile` for the development container
- `compose.yml` with database, Redis, and mailcatcher services
- `devcontainer.json` for VS Code integration

### Docker Scripts

Two helper scripts are provided in `bin/`:
- `bin/dc` - Wrapper for `docker compose` commands targeting the devcontainer
- `bin/dcr` - Wrapper for `docker compose run` with proper TTY and Git configuration

Usage:
```bash
bin/dc up -d          # Start services in background
bin/dc logs -f app    # Follow app logs
bin/dcr rails console # Run Rails console in container
bin/dcr rspec         # Run tests in container
```

### Claude Code Integration

Modulorails can configure your devcontainer for efficient use with Claude Code:
- Persistent bash history across container restarts
- Claude Code configuration volume
- Firewall initialization script

### Bun JS Engine Support

Modulorails detects and supports the Bun JavaScript runtime. When `bun.config.js` is present, the devcontainer will include appropriate JS and CSS build services.

### Other Generators

- **RubocopGenerator** - Configures `.rubocop.yml` with Modulotech standards
- **BundlerauditGenerator** - Sets up bundler-audit for security checks
- **GithooksGenerator** - Installs git hooks for automated checks
- **HealthCheckGenerator** - Configures the health_check gem
- **SidekiqGenerator** - Adds Sidekiq background job processing

## Deprecations (will be removed in 2.0)

The following features are deprecated and will be removed in version 2.0:

### Configuration options
- `config.staging_url`
- `config.review_base_url`
- `config.production_url`
- `config.no_auto_update`

### Services
- `Modulorails::BaseService#log` - Use `Rails.logger.debug` directly
- `Modulorails::LogsForMethodService` - Use `Rails.logger.debug` directly

### Generators
The following generators are deprecated and will be moved to Moduloproject 3.0:
- `Modulorails::DockerGenerator` (and all sub-generators)
- `Modulorails::GitlabciGenerator`
- `Modulorails::ClaudeCodeGenerator`
- `Modulorails::ModuloprojectGenerator`
- `Modulorails::SidekiqGenerator`
- `Modulorails::SelfUpdateGenerator` (will be removed entirely)

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

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/moduloTech/modulorails](https://github.com/moduloTech/modulorails). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/moduloTech/modulorails/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Modulorails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/moduloTech/modulorails/blob/master/CODE_OF_CONDUCT.md).
