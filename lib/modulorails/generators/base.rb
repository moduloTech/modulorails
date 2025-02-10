# frozen_string_literal: true

require 'rails/generators'
require 'yaml'

module Modulorails

  module Generators

    class Base < Rails::Generators::Base

      def self.base_root
        File.expand_path('../../generators', __dir__)
      end

      class_option :force, type: :boolean, default: false

      def call
        return if keep_file_present? && !options['force']

        begin
          create_config
          create_keep_file
        rescue StandardError => e
          warn("[Modulorails][#{generator_name}] Error: #{e.message}")
          warn(e.backtrace.join("\n"))
        end
      end

      protected

      def version
        self.class.const_get('VERSION')
      rescue NameError
        false
      end

      def generator_name
        @generator_name ||= self.class.generator_name
      end

      def keep_file_name
        '.modulorails.yml'
      end

      def keep_file_version
        return @keep_file_version if @keep_file_version

        pathname = Rails.root.join(keep_file_name)
        keep_file_exist = pathname.exist?
        @keep_file_version = if keep_file_exist
                               YAML.load_file(pathname).dig(generator_name, 'version').to_i
                             else
                               0
                             end
      end

      def keep_file_present?
        v = version
        return false unless v

        Rails.root.join(keep_file_name).exist? && keep_file_version >= v
      end

      def create_keep_file
        v = version
        return unless v

        file = keep_file_name
        config = File.exist?(file) ? YAML.load_file(file) : {}
        config[generator_name] = {
          'version' => v
        }

        create_file(file, config.to_yaml, force: true)

        say "Add #{file} to git"
        git add: file
      end

      def create_config
        raise NotImplementedError
      end

      def create_new_file(old_file, new_file, executable: true)
        if File.exist?(old_file)
          copy_original_file old_file, new_file
          remove_file old_file
        else
          template old_file, new_file
        end
        chmod new_file, 0o755 if executable
      end

      def copy_original_file(source, *args, &block)
        config = args.last.is_a?(Hash) ? args.pop : {}
        destination = args.first || source
        source = File.expand_path(source, destination_root)

        create_file destination, nil, config do
          content = File.binread(source)
          content = yield(content) if block
          content
        end
        return unless config[:mode] == :preserve

        mode = File.stat(source).mode
        chmod(destination, mode, config)
      end

      def remove_old_keepfile(filename)
        FileUtils.rm_f(filename)
      end

    end

  end

end
