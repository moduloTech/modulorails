#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# No `node_modules` directory means `yarn install` was never launched.
# It is mandatory to install yarn dependencies IF there is a `package.json` file.
if [ -f package.json ] && [ ! -d node_modules ]
then
  yarn install
fi

# Remove pidfile if it exists else the server will not launch
if [ -f tmp/pids/server.pid ]
then
  rm tmp/pids/server.pid
fi

# Launch the application listening from all origins on port 3000
./bin/bundle exec rails s -b 0.0.0.0 -p 3000
