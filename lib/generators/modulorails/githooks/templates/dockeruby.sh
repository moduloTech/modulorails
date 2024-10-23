#!/bin/sh
set -e

# shellcheck disable=SC2016
VALID_LAST_INSTRUCTION='exec "${@}"'
VALID_LAST_INSTRUCTION2='exec "$@"'

# Check if the Dockerfile exists
check_dockerfile() {
  if [ -f "Dockerfile" ]; then
    return 0
  else
    echo "No Dockerfile"
    return 1
  fi
}

# Get the entrypoint location from the Dockerfile
entrypoint_location() {
  entrypoint_line=$(grep '^ENTRYPOINT' Dockerfile || true)

  if [ -z "$entrypoint_line" ]; then
    echo ""
  else
    echo "$entrypoint_line" | sed -n 's/.*\[\(.*\)\].*/\1/p' | tr -d '"'
  fi
}

# Check if the entrypoint is valid
check_entrypoint() {
  el=$(entrypoint_location)
  if [ -z "$el" ]; then
    return 0
  fi

  if [ ! -f "$el" ]; then
    echo "Entrypoint not found at location: $el"
    return 1
  fi

  last_line=$(tail -n 1 "$el" | xargs)

  if [ "$last_line" != "$VALID_LAST_INSTRUCTION" ] && [ "$last_line" != "$VALID_LAST_INSTRUCTION2" ]; then
    echo "Invalid entrypoint: Last instruction should be '$VALID_LAST_INSTRUCTION' instead of '$last_line'"
    return 1
  fi

  return 0
}

# Run docker with the necessary options
executer_docker_run() {
  pwd=$(pwd)
  working_directory=$(basename "$pwd")

  tty_option=""
  if [ -t 1 ]; then
    tty_option="-ti"
  fi

  command="docker run --rm -v '$pwd:/app/$working_directory' -w '/app/$working_directory' $tty_option $git_environment ezveus/ruby:latest $docker_args"
  echo "$command"
  exec "$command"
}

executer_dockerfile_run() {
  if check_entrypoint; then
    entrypoint_option=""
  else
    entrypoint_option="--entrypoint \"sh -c\""
  fi

  command="docker compose build && docker compose run --rm $tty_option $git_environment $entrypoint_option app $docker_args"
  echo "$command"
  exec "$command"
}

# Main function
main() {
  args="$*"
  docker_args=""
  contains_command=false
  git_name=$(git config --get user.name || whoami)
  git_email=$(git config --get user.email || echo "$git_name@local")
  git_environment="-e \"GIT_AUTHOR_EMAIL=$git_email\" -e \"GIT_AUTHOR_NAME=$git_name\" -e \"GIT_COMMITTER_EMAIL=$git_email\" -e \"GIT_COMMITTER_NAME=$git_name\""

  tty_option=""
  if [ -t 1 ]; then
    tty_option="-ti"
  fi

  for arg in "$@"; do
    # Check if any argument is not an option (doesn't start with '-')
    if [ "${arg#-}" = "$arg" ]; then
      contains_command=true
      break
    fi
  done

  if [ "$contains_command" = false ]; then
    docker_args="ruby $args"
  else
    docker_args="$args"
  fi

  if check_dockerfile; then
    executer_dockerfile_run
  else
    executer_docker_run "$docker_args"
  fi
}

main "$@"
