require 'helper'

class VersionTest < Vault::TestCase
  # Vault::Usage::Client::VERSION is a string matching the `major.minor.patch`
  # format.
  def test_version
    assert_match(/\d+\.\d+\.\d+/, Vault::Usage::Client::VERSION)
  end
end
