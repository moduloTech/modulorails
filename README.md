# Modulorails [![Build Status](https://travis-ci.com/Ezveus/modulorails.svg?branch=master)](https://travis-ci.com/Ezveus/modulorails)

**Modulorails** is the common base for the Ruby on Rails project at [Modulotech](https://www.modulotech.fr/).

It registers each application using it on the company's intranet,
provides templates for the common configurations and defines common dependencies.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'modulorails', git: 'git://github.com/moduloTech/modulorails.git'
```

And then execute:

    $ bundle install

## Usage

To work the gem needs to be configured. Add an initializer `config/modulorails.rb`:

```ruby
Modulorails.configure do |config|
  config.name 'The usual name of the application'
  config.main_developer 'The email of the main developer/maintainer of the application'
  config.project_manager 'The email of the project manager of the application'
  config.endpoint 'The url to the intranet'
  config.api_key 'The API key'
end
``` 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/moduloTech/modulorails](https://github.com/moduloTech/modulorails). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/moduloTech/modulorails/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Modulorails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/moduloTech/modulorails/blob/master/CODE_OF_CONDUCT.md).
