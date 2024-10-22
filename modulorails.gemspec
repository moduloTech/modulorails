require_relative 'lib/modulorails/version'

Gem::Specification.new do |spec|
  spec.name          = 'modulorails'
  spec.version       = Modulorails::VERSION
  spec.authors       = ['Matthieu Ciappara']
  spec.email         = ['ciappa_m@modulotech.fr']

  spec.summary       = 'Common base for Ruby on Rails projects at Modulotech'
  spec.description = <<~END_OF_TEXT
    Modulorails is the common base for the Ruby on Rails project at Modulotech
    (https://www.modulotech.fr/).

    It registers each application using it on the company's intranet, provides templates for the
    common configurations and defines common dependencies.
  END_OF_TEXT
  spec.homepage      = 'https://github.com/moduloTech/modulorails'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/moduloTech/modulorails/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'bundler-audit', '~> 0.9.1'
  spec.add_dependency 'git', '~> 1.7', '>= 1.7.0'
  spec.add_dependency 'health_check', '~> 3.1'
  spec.add_dependency 'httparty', '>= 0.13.3'
  spec.add_dependency 'i18n', '>= 0.9.5'
  spec.add_dependency 'railties', '>= 4.2.0'
  spec.add_dependency 'rubocop', '>= 1.28.2'
  spec.add_dependency 'rubocop-rails', '>= 2.14.2'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
