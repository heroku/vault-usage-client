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

## Using the client from the command-line

The `bin/vault-usage` command-line tool can be used to quickly see
usage data for a particular user:

```bash
export VAULT_USAGE_URL=https://username:secret@vault-usage.herokuapp.com
bin/vault-usage user123@heroku.com 2013-01-01 2013-02-01
```

## Using the client in Ruby

The `Vault::Usage` API may only be accessed with valid credentials.
You must supply these when you create a new client:

```ruby
require 'vault-usage-client'

client = Vault::Usage::Client.new(
  'https://username:secret@vault-usage.herokuapp.com')
```

### Usage events

Usage events represent usage of a product, for a period of time, by an
app or user.

#### Opening a usage event

Each usage event must have a unique UUID provided by the service
reporting it and the start time must be in UTC:

```ruby
event_id = SecureRandom.uuid
product_name = 'platform:dyno:logical'
consumer_hid = 'app1234@heroku.com'
start_time = Time.now.getutc
client.open_usage_event(event_id, product_name, consumer_hid, start_time)
```

Arbitrary data related to the usage event can optionally be provided
by way of a detail object:

```ruby
event_id = SecureRandom.uuid
product_name = 'platform:dyno:logical'
consumer_hid = 'app1234@heroku.com'
start_time = Time.now.getutc
detail = {type: 'web',
          description: 'bundle exec bin/web',
          kernel: 'us-east-1-a'}
client.open_usage_event(event_id, product_name, consumer_hid, start_time,
                        detail)
```

Keys in the detail object must be of type `Symbol` and values may only
be of type `String`, `Fixnum`, `Bignum`, `Float`, `TrueClass`,
`FalseClass` or `NilClass`.  In other words, it's not possible to use
nested structures in the detail object.

#### Closing a usage event

Closing a usage event works the same way as opening one:

```ruby
event_id = SecureRandom.uuid
product_name = 'platform:dyno:logical'
consumer_hid = 'app1234@heroku.com'
stop_time = Time.now.getutc
client.close_event(event_id, product_name, consumer_hid, stop_time)
```

#### Retrieving usage information

Usage information for a particular user can be retrieved by the
client.  The start and stop time must both be specified in UTC:

```ruby
user_hid = 'user1234@heroku.com'
start_time = Time.utc(2013, 1)
stop_time = Time.utc(2013, 2)
events = client.usage_for_user(user_hid, start_time, stop_time)
```

The `events` result is an `Array` of objects matching this format:

```ruby
[{id: '<event-uuid>',
  product: '<name>',
  consumer: '<consumer-hid>',
  start_time: <Time>,
  stop_time: <Time>,
  detail: {<key1>: <value1>,
           <key2>: <value2>,
           ...}},
  ...]
```

In some cases it can be useful to exclude event data for certain
products:

```ruby
user_hid = 'user1234@heroku.com'
start_time = Time.utc(2013, 1)
stop_time = Time.utc(2013, 2)
events = client.usage_for_user(user_hid, start_time, stop_time,
                               ['platform:dyno:physical'])
```

You can pass one or more product names to exclude.

#### Retrieving a single usage event

A usage event can be retrieved with the client:

```
event_id = '3b1086ea-07df-4324-a35f-b28a1474bd9b'
event = client.usage_for_event(event_id)
```

The `event` result is an object matching this format:

```ruby
{id: '<event-uuid>',
  product: '<name>',
  consumer: '<consumer-hid>',
  start_time: <Time>,
  stop_time: <Time>,
  detail: {<key1>: <value1>,
           <key2>: <value2>,
           ...}}
```

### App ownership events

App ownership events represent ownership of an app, for a period of
time, by a user.

#### Opening an app ownership event

Each app ownership event must have a unique UUID provided by the
service reporting it and the start time must be in UTC:

```ruby
event_id = SecureRandom.uuid
user_hid = 'user1234@heroku.com'
app_hid = 'app1234@heroku.com'
start_time = Time.now.getutc
client.open_app_ownership_event(event_id, user_hid, app_hid, start_time)
```

#### Closing an app ownership event

Closing an app ownership event works the same way as opening one:

```ruby
event_id = SecureRandom.uuid
user_hid = 'user1234@heroku.com'
app_hid = 'app1234@heroku.com'
stop_time = Time.now.getutc
client.close_app_ownership_event(event_id, user_hid, app_hid, stop_time)
```

## License

The MIT License (MIT)

Copyright (c) 2014 Heroku

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
