#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Launch the tests
bundle exec appraisal rake spec
