#!/usr/bin/ruby
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

def check_dockerfile(verbose: false)
  return true if File.exist?('Dockerfile')

  puts('No Dockerfile') if verbose
  false
end

def entrypoint_location
  entrypoint_line = File.readlines('Dockerfile').find { |line| line.start_with?('ENTRYPOINT') }

  return nil if entrypoint_line.nil?

  md = /\[["'](.+)["']\]/.match(entrypoint_line)
  return nil if md.nil? || md[1].nil?

  md[1]
end

VALID_LAST_INSTRUCTION = /exec "\$\{?@}?"/

def check_entrypoint(verbose: false)
  el = entrypoint_location
  return true if el.nil?

  unless File.exist?(el)
    warn("Entrypoint not found at location: #{el}") if verbose
    return false
  end

  last_line = File.readlines(el).last&.strip
  return true if VALID_LAST_INSTRUCTION.match?(last_line)

  warn("Invalid entrypoint: Last instruction should be 'exec \"${@}\"' instead of '#{last_line}'") if verbose

  false
end

def executer_docker_run(docker_args, verbose: false)
  pwd = Dir.pwd
  working_directory = File.basename(pwd)

  volumes = `docker volume ls -q -f name=modulogem`
  volumes = volumes.split("\n").map(&:strip)
  modulogem_gems = volumes.find { |volume| volume.include?('modulogem_gems') }
  modulogem = volumes.find { |volume| volume.include?('modulogem') }
  modulogem_gems_option = modulogem_gems.nil? ? '' : "-v #{modulogem_gems}:/usr/local/bundle"
  modulogem_option = modulogem.nil? ? '' : "-v #{modulogem}:/root"

  # Check if the shell is a TTY
  tty_option = $stdout.isatty ? '-ti' : ''

  # Build the command string
  # rubocop:disable Layout/LineLength
  command = %(docker run --rm #{modulogem_gems_option} #{modulogem_option} -v '#{pwd}:/app/#{working_directory}' #{tty_option} -w '/app/#{working_directory}' ezveus/ruby:latest #{docker_args})
  # rubocop:enable Layout/LineLength

  puts(command) if verbose
  exec(command)
end

def executer_compose_run(docker_args, verbose: false)
  entrypoint_option = check_entrypoint(verbose: verbose) ? '' : '--entrypoint "sh -c"'
  git_email = `git config --get user.email`.strip
  git_name = `git config --get user.name`.strip

  # Check if the shell is a TTY
  tty_option = $stdout.isatty ? '-ti' : ''

  # rubocop:disable Layout/LineLength
  command = %(docker compose build && docker compose run --rm #{tty_option} -e "GIT_AUTHOR_EMAIL=#{git_email}" -e "GIT_AUTHOR_NAME=#{git_name}" -e "GIT_COMMITTER_EMAIL=#{git_email}" -e "GIT_COMMITTER_NAME=#{git_name}" #{entrypoint_option} app)
  command = if entrypoint_option == ''
              "#{command} #{docker_args}"
            else
              "#{command} '#{docker_args}'"
            end
  # rubocop:enable Layout/LineLength
  puts(command) if verbose
  exec(command)
end

def main(args, verbose: false)
  # Escape each argument individually
  escaped_args = args.map { |arg| Shellwords.escape(arg) }

  # Check if the arguments contain a Ruby command or only options
  contains_command = false
  escaped_args.each_with_index do |arg, index|
    if !arg.start_with?('-') && (index.zero? || !escaped_args[index - 1].start_with?('-'))
      contains_command = true
      break
    end
  end

  docker_args = if contains_command
                  escaped_args.join(' ')
                else
                  "ruby #{escaped_args.join(' ')}"
                end

  if check_dockerfile(verbose: verbose)
    executer_compose_run(docker_args, verbose: verbose)
  else
    executer_docker_run(docker_args, verbose: verbose)
  end
end

main(ARGV, verbose: true)
