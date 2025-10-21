# frozen_string_literal: true

require 'modulorails/generators/base'

class Modulorails::ClaudeCodeGenerator < Modulorails::Generators::Base

  VERSION = 1

  desc 'This generator configures the devcontainer to use Claude Code efficiently'

  protected

  def create_config
    @data = Modulorails.data
    @image_name = @data.name.parameterize
    @environment_name = @data.environment_name
    @adapter = @data.adapter
    @review_base_url = @data.review_base_url
    @staging_url = @data.staging_url
    @production_url = @data.production_url

    template 'bin/init-firewall.sh'
    inject_into_file(Rails.root.join('bin/setup'), "\n  puts \"== Setting up firewall rules ==\"\n  system(\"bin/init-firewall.sh\")\n", after: "APP_ROOT do")
    inject_into_file(Rails.root.join('.devcontainer/devcontainer.json'), after: '"shutdownAction": "stopCompose",') do
      <<-JSON

  "mounts": [
    "source=claude-code-bashhistory,target=/commandhistory,type=volume",
    "source=claude-code-config,target=/root/.claude,type=volume"
  ],

	"remoteEnv": {
    "NODE_OPTIONS": "--max-old-space-size=4096",
    "CLAUDE_CONFIG_DIR": "/root/.claude"
	},

      JSON
    end
    inject_into_file(Rails.root.join('.devcontainer/Dockerfile'), before: 'RUN gem install bundler') do
      <<-DOCKERFILE
ENV DEVCONTAINER=true

#{"RUN apk add npm" unless File.read(Rails.root.join('.devcontainer/Dockerfile')).match?(/npm/)}

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history

RUN mkdir -p /root/.claude

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Install Claude
RUN npm install -g @anthropic-ai/claude-code

      DOCKERFILE
    end
  rescue StandardError => e
    warn("[Modulorails] Error: cannot configure Claude Code: #{e.message}")
  end

end
