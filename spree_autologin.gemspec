# encoding: UTF-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_autologin/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_autologin'
  s.version     = SpreeAutologin.version
  s.summary     = 'Admin auto-login flow for vendor onboarding'
  s.description = 'Creates or signs in vendor users and redirects them into the Spree admin area.'
  s.required_ruby_version = '>= 3.1'

  s.author    = 'stevehoober254'
  s.email     = 'stephen@olitt.com'
  s.homepage  = 'https://github.com/your-github-handle/spree_autologin'
  s.license = 'BSD-3-Clause'

  s.files       = `git ls-files`.split("\n").reject { |f| f.match(/^spec/) && !f.match(/^spec\/fixtures/) }
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree', '~> 5.0'
  s.add_dependency 'spree_admin', '~> 5.0'
  s.add_dependency 'spree_extension'

  s.add_development_dependency 'spree_dev_tools'
end
