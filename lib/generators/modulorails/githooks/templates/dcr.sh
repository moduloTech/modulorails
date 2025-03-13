#!/usr/bin/env bash

# Function to run the main docker command
run_command() {
    local docker_args="$1"

    # Get Git configuration
    local git_email
    git_email=$(git config --get user.email)
    local git_name
    git_name=$(git config --get user.name)

    # Check if the shell is a TTY
    local tty_option
    if [ -t 1 ]; then
        tty_option='-ti'
    else
        tty_option=''
    fi

    # Build the docker command
    local command="docker compose -f .devcontainer/compose.yml build && \
        docker compose --project-name \"\$(basename \$(pwd))_devcontainer\" -f .devcontainer/compose.yml run --rm $tty_option \
        -e \"GIT_AUTHOR_EMAIL=$git_email\" -e \"GIT_AUTHOR_NAME=$git_name\" \
        -e \"GIT_COMMITTER_EMAIL=$git_email\" -e \"GIT_COMMITTER_NAME=$git_name\" app"

    # Execute the command with additional arguments
    eval "$command $docker_args"
}

main() {
    # Check for apk command to determine if we're in an Alpine Linux container
    if ! command -v apk >/dev/null 2>&1; then
        # Escape arguments and pass them to the docker command
        local escaped_args=()
        for arg in "$@"; do
            escaped_args+=("$(printf '%q' "$arg")")
        done
        run_command "${escaped_args[*]}"
    else
        # Execute the given arguments without wrapping
        exec "$@"
    fi
}

# Pass all the script's arguments to the main function
main "$@"
