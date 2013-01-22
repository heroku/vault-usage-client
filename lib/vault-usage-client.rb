require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require 'excon'
require 'yajl/json_gem'

module Vault
  module Usage
    # Client provides a Ruby API to access the Vault::Usage HTTP API.
    class Client
    end
  end
end

require 'vault-usage-client/client'
require 'vault-usage-client/version'
