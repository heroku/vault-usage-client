# Vault::Usage::Client

Client provides a Ruby API for interacting with the `Vault::Usage`
HTTP API.

## Setting up a development environment

Install dependencies and run the test suite:

    bundle install --binstubs vendor/bin
    rbenv rehash
    rake

Run tests:

    rake test

See tasks:

    rake -T

Generate API documentation:

    rake yard

## Using the client

The `Vault::Usage` API may only be accessed with valid credentials.
You must supply these when you create a new client:

```ruby
require 'vault-usage-client'

client = Vault::Usage::Client.create('username', 'password')
```

Requests are made to `https://vault-usage.herokuapp.com` by default.
You can optionally specify a different host, which will be accessed
securely using HTTPS:

```ruby
client = Vault::Usage::Client.create('username', 'password',
                                     'vault-usage.example.com')
```

### Opening an event

A usage event represents usage of a product, for a period of time, by
an app or user.  Each event must have a unique ID provided by the
service reporting it and the start time must be in UTC:

```ruby
event_id = SecureRandom.uuid
product_name = 'platform:dyno:logical'
heroku_id = 'app1234@heroku.com'
start_time = Time.utc
client.open_event(event_id, product_name, heroku_id, start_time)
```

Arbitrary data related to the event can optionally be provided by way
of a detail object:

```ruby
event_id = SecureRandom.uuid
product_name = 'platform:dyno:logical'
heroku_id = 'app1234@heroku.com'
start_time = Time.utc
detail = {type: 'web',
          description: 'bundle exec bin/web',
          kernel: 'us-east-1-a'}
client.open_event(event_id, product_name, heroku_id, start_time, detail)
```

Keys in the detail object must be of type `Symbol` and values may only
be of type `String`, `Fixnum`, `Bignum`, `Float`, `TrueClass`,
`FalseClass` or `NilClass`.  In other words, it's not possible to use
nested structures in the detail object.

### Closing an event

Closing an event works the same way as opening an event:

```ruby
event_id = SecureRandom.uuid
product_name = 'platform:dyno:logical'
heroku_id = 'app1234@heroku.com'
stop_time = Time.utc
client.open_event(event_id, product_name, heroku_id, stop_time)
```

### Retrieving usage information

Usage information for a particular user can be retrieved by the
client.  The start and stop time must both be specified in UTC:

```ruby
user_id = 'user1234@heroku.com'
start_time = Time.utc(2013, 1)
stop_time = Time.utc(2013, 2)
events = client.usage_for_user(user_id, start_time, stop_time)
```

The `events` result is an `Array` of objects matching this format:

```ruby
[{id: '<event-uuid>',
  product: '<name>',
  consumer: '<heroku-id>',
  start_time: <Time>,
  stop_time: <Time>,
  detail: {<key1>: <value1>,
           <key2>: <value2>,
           ...}},
  ...]}
```

In some cases it can be useful to exclude event data for certain
products:

```ruby
user_id = 'user1234@heroku.com'
start_time = Time.utc(2013, 1)
stop_time = Time.utc(2013, 2)
events = client.usage_for_user(user_id, start_time, stop_time,
                               exclude=['platform:dyno:physical'])
```

You can pass one or more product names to exclude.
