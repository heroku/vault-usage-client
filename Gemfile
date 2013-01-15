source :rubygems

gemspec
# FIXME Why is the following necessary?  The dependencies are declared in
# vault-usage-client.gemspec...?
gem 'excon'
gem 'yajl-ruby', :require => 'yajl/json_gem'

group :development do
  gem 'rake'
end

group :test do
  gem 'rr'
  gem 'vault-test-tools', '~> 0.2.2', :git => 'https://github.com/heroku/vault-test-tools.git'
end
