#  CHANGELOG

This file is used to list changes made in each version of the gem.

# Unreleased

# 1.6.0

- Fix typo in `database.yml` template for test database.
- Fix removal of rails' server's pidfile in docker entrypoint.
- Split DockerGenerator in multiple sub-generators to version each one individually.
- Merge all keepfiles in one.
- Wrap health_check initializer in a reloader.to_prepare block.
- Add `Modulorails.deprecator` for better compatibility with Rails 7.2.
- Check if generated files have to be regenerated in `refresh_generations.sh` to speed-up hook.
- Allow `class_methods` and `included` blocks in Concerns to break the `Metrics/BlockLength` Rubocop rule.
- Add devcontainer support and update Docker-related structure.
- Force overwrite of keep_file.
- Force overwrite of config files.
- Replace old Modulotech `Dockerfile.prod` with Rails one.
- Update production.rb from ModuloprojectGenerator to fit Rails 8.
- Replace `dockeruby.rb` with two bash scripts: `dc` to wrap `docker compose` and `dcr` for `docker compose run`.
- Update Sidekiq generator to fit devcontainers.
- Add support for `Bun` JS engine.
- Update Gitlab CI generator to fit devcontainers.
- Update Gitlab CI generator for better test environment.
- Allow commented lines to break the `Layout/LineLength` Rubocop rule.

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
