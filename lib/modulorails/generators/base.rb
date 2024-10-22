# frozen_string_literal: true

require 'rails/generators'

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
        1
      end

      def generator_name
        self.class.name.split('::').last.gsub('Generator', '').parameterize
      end

      def keep_file_name
        ".modulorails-#{generator_name}"
      end

      def keep_file_present?
        pathname = Rails.root.join(keep_file_name)

        res = pathname.exist?
        return res if version < 2

        res && pathname.readlines(keep_file_name).first
                       .match(/version: (\d+)/i)&.send(:[], 1).to_i >= version
      end

      def create_keep_file
        file = keep_file_name

        remove_file(file)

        content = <<~TEXT
          Version: #{version}

          If you want to reset your configuration, you can run `rails g modulorails:#{generator_name} --force`.
        TEXT
        create_file(file, content)

        say "Add #{file} to git"
        git add: file
      end

      def create_config
        raise NotImplementedError
      end

    end

  end

end
