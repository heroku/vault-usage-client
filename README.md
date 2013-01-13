# Vault::Usage::Client

Client provides a Ruby API for interacting with the `Vault::Usage`
HTTP API.

## Setting up a development environment

Install dependencies and setup test databases:

    bundle install --binstubs vendor/bin
    rbenv rehash
    rake

Run tests:

    rake test

See tasks:

    rake -T

Generate API documentation:

    rake yard
