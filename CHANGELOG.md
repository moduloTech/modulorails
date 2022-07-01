#  CHANGELOG

This file is used to list changes made in each version of the gem.

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
