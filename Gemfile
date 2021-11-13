source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'spree', github: 'spree/spree', branch: 'main'
# gem 'spree_backend', github: 'spree/spree', branch: 'main'
gem 'device'


group :test do
  gem 'rake', require: false
  gem 'rspec', require: false
end

group :development do
  gem 'rcodetools', require: false
  gem 'reek', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'solargraph', require: false
end

gemspec
