#!/usr/bin/env bash

# Function to run the main docker command
run_command() {
    local docker_args="$1"

    # Build the docker command
    local command="docker compose --project-name \"\$(basename \$(pwd))_devcontainer\" -f .devcontainer/compose.yml"

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
