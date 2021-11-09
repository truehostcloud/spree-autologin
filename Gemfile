source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'spree', github: 'spree/spree', branch: 'main', ref: '354945d2095cdd0ab47374f25d011a0fb1337a09'
# gem 'spree_backend', github: 'spree/spree', branch: 'main'
gem 'rails-controller-testing'
gem 'device'

gemspec
