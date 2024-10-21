#!/bin/sh

echo 'Regenerate Gemfile.lock'
bundle install

# echo 'Regenerate JS translations'
# rake i18n:js:export

echo 'Regenerate DB schema'
export RAILS_ENV=test
bundle exec rake db:drop db:create db:schema:load db:migrate
export RAILS_ENV=development

git add Gemfile.lock app/assets/javascripts/i18n/translations.js db/schema.rb
if [ "$(git diff --cached --name-only | wc -l)" -ne 0 ]; then
  echo "Commit regenerated files by $GIT_AUTHOR_NAME <$GIT_AUTHOR_EMAIL>"
  git commit -m 'hook: Update generated files'
else
  echo 'Nothing to commit'
fi
