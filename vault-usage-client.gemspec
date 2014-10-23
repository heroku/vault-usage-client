lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vault-usage-client/version'

Gem::Specification.new do |gem|
  gem.name          = 'vault-usage-client'
  gem.version       = Vault::Usage::Client::VERSION
  gem.authors       = ['Chris Continanza', 'Jamu Kakar']
  gem.email         = ['csquared@heroku.com', 'jkakar@heroku.com']
  gem.description   = 'Client for Vault::Usage'
  gem.summary       = 'A simple wrapper around the Vault::Usage HTTP API'
  gem.homepage      = 'https://github.com/heroku/vault-usage-client'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep('^(test|spec|features)/')
  gem.require_paths = ['lib']
  gem.executables   = ['vault-usage']

  gem.add_development_dependency 'pry'

  gem.add_dependency 'excon'
  gem.add_dependency 'multi_json'
  gem.add_dependency 'colorize'
end
