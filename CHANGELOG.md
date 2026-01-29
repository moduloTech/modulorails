#  CHANGELOG

This file is used to list changes made in each version of the gem.

# Unreleased

# 1.6.0

The devcontainer release.

## Features

- Add devcontainer support (`.devcontainer/` with Dockerfile, compose.yml, devcontainer.json).
- Add Claude Code generator for devcontainer (native installation).
- Add `Bun` JS engine support.
- Add `bin/dc` and `bin/dcr` scripts to wrap `docker compose` commands.

## Improvements

- Split DockerGenerator in multiple sub-generators for individual versioning.
- Merge all keepfiles into `.modulorails.yml`.
- Force overwrite of keepfile and config files.
- Speed-up git hooks by checking if regeneration is needed in `refresh_generations.sh`.
- Add `Modulorails.deprecator` for Rails 7.2+ compatibility.
- Wrap health_check initializer in `reloader.to_prepare` block.
- Update Rubocop rules:
  - Allow `class_methods`/`included` blocks in Concerns to break `Metrics/BlockLength`.
  - Allow commented lines to break `Layout/LineLength`.
- Update generators for devcontainers (Sidekiq, GitLab CI).
- Update production.rb template for Rails 8.
- Replace old `Dockerfile.prod` with Rails-standard one.

## Fixes

- Fix typo in `database.yml` template for test database.
- Fix removal of rails server's pidfile in docker entrypoint.

## Deprecations (will be removed in 2.0)

- Configuration options: `config.staging_url`, `config.review_base_url`, `config.production_url`, `config.no_auto_update`.
- `Modulorails::SelfUpdateGenerator`.
- Infrastructure generators (use Moduloproject 3.0, available later):
  - `DockerGenerator` and all sub-generators
  - `GitlabciGenerator`
  - `ClaudeCodeGenerator`
  - `ModuloprojectGenerator`
  - `SidekiqGenerator`

# 1.5.1

- Update templates according to new standards:
  - Optimize layers in Dockerfile.prod.
  - Remove root privileges in Dockerfile.prod.
  - Exec Docker `CMD` in entrypoints.
  - Configure Puma and Redis.
  - Remove docker-compose.prod.
  - Rename docker-compose.yml to compose.yml.
  - Remove version from compose.yml.
  - Auto-stop staging container after 7 days.
  - Use `rails` chart in Gitlab CI templates.
  - Move entrypoints locations to `bin` to be rails-standard.
  - Rewrite Dockerfile.prod for Rails 7.2+ to be more rails-standard.
- Version Docker generator.
- Add a generator for project initialization:
  - Add default configuration for production and staging environments.
  - Add default locale configuration to application.rb.
- Add a generator for Git hooks.
- Update service template to use keyword arguments and add `attr_reader`s.
- Add optional `data` argument to `with_transaction`.
- Deprecate `Modulorails::BaseService#log` and `Modulorails::LogsForMethodService`.
- Add a common base for all generators.

# 1.5.0

- Released then yanked for critical bugs.

# 1.4.0.1

- Fix auto-update.

# 1.4.0

- Remove custom from standard health_check checks.
- Update Postgres version from 15 to 16 in templates.
- Fix template of `Dockerfile.prod` to install valid version of `bundler`.
- Check required Ruby version of next Modulorails version before auto-update.
- Remove Modulorails::Validators::DatabaseConfiguration since, with Docker Compose, it is no more necessary.

# 1.3.2

- Fix missing symbol in docker and gitlabci generators.

# 1.3.1

- Update templates according to new devops standards:
  - Add exec commands in entrypoints.
  - Upgrade PG and Redis version in docker-compose files.
  - Upgrade PG and Redis version in test stage in CI.
  - Add default SECRET_KEY_BASE and optional `yarn install` in `Dockerfile.prod` templates.
  - Add templates for Kubernetes values files.
  - Append sidekiq in Kubernetes values files in Sidekiq generator.

# 1.3.0

- Update redis configuration in generators.
- Update mailcatcher docker image for better compatibility with ARM64.
- Remove possible suffix `Service` in service generator.
- Update rubocop configuration in template.
- Add a generator to add Sidekiq to a project.
- Update docker generator to use valid names for environment variables.

# 1.2.1

- Update rubocop configuration.

# 1.2.0

The 'audit' release.

- Add bundler-audit in CI.
- Make the rubocop configuration work during CI.
- Fix generation of .gitlab-ci.yml for PG databases.
- Remove deprecated `--deployment` flag from Dockerfile.prod

# 1.1.0

The 'new project' release.

- Add lot of Rubocop rules.
- Fix rubocop offenses for the gem.
- Ensure Modulorails will work with Moduloproject.
- Add `webpacker`, `importmap` and `jsbundling` versions to `Modulorails::Data`.

# 1.0.2

Fix error in with_transaction: `uninitialized constant Modulorails::BaseService::ErrorData`.

# 1.0.1

First Rubocop rules.

- Add Style/StringLiterals, Style/QuotedSymbols and Lint/SymbolConversion.

# 1.0.0

The Rubocop release.

- Add Modulorails helper `powered_by`.
- Add `Modulorails::BaseService`, `Modulorails::LogsForMethodService`,
  `Modulorails::SuccessData` and `Modulorails::ErrorData`.
- Add Rubocop dependency with empty configuration.
- Ensure the compatibility of the gem with Ruby 3.0 and Ruby 3.1.

# 0.4.0

Fixes, updates and health_check release.

- Update generators for Docker and Gitlab CI.
- Move all generators under the `modulorails` namespace.
- Add dependency to `health_check` gem.
- Fix error on database configuration validator when no database.yml exists.
- Rescue if httparty can't post to configuration.endpoint.
- Add dockerfiles to test on many Ruby versions.
- Add appraisal to test on many Rails versions.

# 0.3.0

Docker release.

- Add generator for Docker.
- Use templates for Gitlabci generator.

# 0.2.3

Gitlab-ci generator.

- Fixes the Ruby version put in the generated `.gitlab-ci.yml`.

# 0.2.2

Auto-update fixes.

- Run `bundle install` to update the `Gemfile.lock` on auto-update.

# 0.2.1

Minor fixes.

- Fixes some errors occuring on a project where database can not be accessed.

# 0.2.0

Auto-update release.

- Add auto-update feature.

# 0.1.0

Initial release.

- Send configuration to intranet.
- Write CI/CD templates.
- Check database configuration.
