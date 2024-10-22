#!/bin/sh

echo 'Regenerate Gemfile.lock'
bundle install
git add Gemfile.lock

if [ $(cat Gemfile.lock | grep i18n-js | wc -l) -gt 0 ]
then
  echo 'Regenerate JS translations'
  rake i18n:js:export
  git add app/assets/javascripts/i18n/translations.js
fi

echo 'Regenerate DB schema'
export RAILS_ENV=test
bundle exec rake db:drop db:create db:schema:load db:migrate
git add db/schema.rb
export RAILS_ENV=development

if [ "$(git diff --cached --name-only | wc -l)" -ne 0 ]; then
  echo "Commit regenerated files by $GIT_AUTHOR_NAME <$GIT_AUTHOR_EMAIL>"
  git commit -m 'hook: Update generated files'
else
  echo 'Nothing to commit'
fi
