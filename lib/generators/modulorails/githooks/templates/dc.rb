#!/usr/bin/env ruby
# frozen_string_literal: true

def require_or_install(gem_name, version=nil)
  gem(gem_name, "~> #{version}") unless version.nil?
  require gem_name
rescue LoadError
  warn "Installing gem #{gem_name}"
  if version.nil?
    Gem.install(gem_name)
  else
    Gem.install(gem_name, "~> #{version}")
    gem(gem_name, "~> #{version}")
  end
  require gem_name
end

require_or_install('shellwords')

def run_command(docker_args)
  git_email = `git config --get user.email`.strip
  git_name = `git config --get user.name`.strip

  # Check if the shell is a TTY
  tty_option = $stdout.isatty ? '-ti' : ''

  command = %(docker compose -f .devcontainer/compose.yml build && \
docker compose --project-name "$(basename `pwd`)_devcontainer" -f .devcontainer/compose.yml run --rm #{tty_option} \
-e "GIT_AUTHOR_EMAIL=#{git_email}" -e "GIT_AUTHOR_NAME=#{git_name}" \
-e "GIT_COMMITTER_EMAIL=#{git_email}" -e "GIT_COMMITTER_NAME=#{git_name}" app)

  exec("#{command} #{docker_args}")
end

def contains_command(escaped_args)
  escaped_args.each_with_index.any? do |arg, index|
    !arg.start_with?('-') && (index.zero? || !escaped_args[index - 1].start_with?('-'))
  end
end

def main(args)
  # If we are in the dev container, no need for wrapping
  exec(args.join(' ')) unless ENV['REMOTE_CONTAINERS'].nil? && ENV['DEVCONTAINER_CONFIG_PATH'].nil?

  # Escape each argument individually
  escaped_args = args.map { |arg| Shellwords.escape(arg) }

  # Prefix the arguments with a `ruby` command if there is not already one
  docker_args = if contains_command(escaped_args)
                  escaped_args.join(' ')
                else
                  "ruby #{escaped_args.join(' ')}"
                end

  run_command(docker_args)
end

main(ARGV)
