appraise 'rails-52' do
  gem 'rails', '~> 5.2', '>= 5.2.6'
end

appraise 'rails-60' do
  gem 'rails', '~> 6.0', '>= 6.0.4.4'
end

appraise 'rails-61' do
  gem 'rails', '~> 6.1', '>= 6.1.4.4'
end

# Rails 7 requires at least Ruby 2.7
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7')
  appraise 'rails-70' do
    gem 'rails', '~> 7.0'
  end
end
