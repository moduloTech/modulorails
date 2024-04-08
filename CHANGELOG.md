#  CHANGELOG

This file is used to list changes made in each version of the gem.

# Unreleased

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
