#!/usr/bin/env bash

# Function to run the main docker command
run_command() {
    local docker_args="$1"

    # Build the docker command
    local command="docker compose --project-name \"\$(basename \$(pwd))_devcontainer\" -f .devcontainer/compose.yml run"

    # Execute the command with additional arguments
    eval "$command $docker_args"
}

main() {
    # Check for specific environment variables to determine whether to wrap the command
    if [ -z "$REMOTE_CONTAINERS" ] && [ -z "$DEVCONTAINER_CONFIG_PATH" ]; then
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
