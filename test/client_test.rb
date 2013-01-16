require 'helper'

class ClientTest < Vault::TestCase
  def setup
    super
    Excon.stubs.clear
    Excon.defaults[:mock] = true
    @client = Vault::Usage::Client::Client.new(
      'https://username:secret@vault-usage.herokuapp.com')
    @event_id = 'd8bb95d1-6279-4488-961d-133514b772fa'
    @product_name = 'platform:dyno:logical'
    @app_id = 'app123@heroku.com'
    @user_id = 'user456@heroku.com'
    @start_time = Time.utc(2013, 1)
    @stop_time = Time.utc(2013, 2)
  end

  def teardown
    # FIXME This is a bit ugly, but Excon doesn't provide a builtin way to
    # ensure that a request was invoked, so we have to do it ourselves.
    # Without this, and the Excon.stubs.pop calls in the tests below, tests
    # will pass if request logic is completely removed from application
    # code. -jkakar
    assert(Excon.stubs.empty?, 'Expected HTTP requests were not made.')
    super
  end

  # Convert a time to an ISO 8601 combined data and time format.
  def iso_format(time)
    time.strftime('%Y-%m-%dT%H:%M:%SZ')
  end

  # Client.open_event makes a POST request to the Vault::Usage HTTP API,
  # passing the supplied credentials using HTTP basic auth, to report that
  # usage of a product began at a particular time.
  def test_open_event
    Excon.stub(method: :post) do |request|
      assert_equal('Basic dXNlcm5hbWU6c2VjcmV0',
                   request[:headers]['Authorization'])
      assert_equal('vault-usage.herokuapp.com:443', request[:host_port])
      assert_equal("/products/#{@product_name}/usage/#{@app_id}" +
                   "/events/#{@event_id}/open/#{iso_format(@start_time)}",
                   request[:path])
      Excon.stubs.pop
      {status: 200}
    end
    @client.open_event(@event_id, @product_name, @app_id, @start_time)
  end

  # Client.open_event optionally accepts a detail hash which is sent as a JSON
  # payload in the request body when provided.
  def test_open_event_with_detail
    detail = {type: 'web',
              description: 'bundle exec bin/web',
              kernel: 'us-east-1-a'}
    Excon.stub(method: :post) do |request|
      assert_equal('application/json', request[:headers]['Content-Type'])
      assert_equal(detail,
                   Yajl::Parser.parse(request[:body], {symbolize_keys: true}))
      Excon.stubs.pop
      {status: 200}
    end
    @client.open_event(@event_id, @product_name, @app_id, @start_time,
                       detail)
  end

  # Client.open_event raises an InvalidTimeError if the start time is not in
  # UTC.
  def test_open_event_with_non_utc_start_time
    start_time = Time.new(2013, 1, 12, 15, 25, 0, '+09:00')
    error = assert_raises Vault::Usage::Client::InvalidTimeError do
      @client.open_event(@event_id, @product_name, @app_id, start_time)
    end
    assert_equal('Start time must be in UTC.', error.message)
  end

  # Client.open_event raises the appropriate Excon::Errors::HTTPStatusError if
  # an unsuccessful HTTP status code is returned by the server.
  def test_open_event_with_unsuccessful_response
    Excon.stub(method: :post) do |request|
      Excon.stubs.pop
      {status: 400, body: 'Bad inputs provided.'}
    end
    assert_raises Excon::Errors::BadRequest do
      @client.open_event(@event_id, @product_name, @app_id, @start_time)
    end
  end

  # Client.close_event makes a POST request to the Vault::Usage HTTP API,
  # passing the supplied credentials using HTTP basic auth, to report that
  # usage of a product ended at a particular time.
  def test_close_event
    Excon.stub(method: :post) do |request|
      assert_equal('Basic dXNlcm5hbWU6c2VjcmV0',
                   request[:headers]['Authorization'])
      assert_equal('vault-usage.herokuapp.com:443', request[:host_port])
      assert_equal("/products/#{@product_name}/usage/#{@app_id}" +
                   "/events/#{@event_id}/close/#{iso_format(@stop_time)}",
                   request[:path])
      Excon.stubs.pop
      {status: 200}
    end
    @client.close_event(@event_id, @product_name, @app_id, @stop_time)
  end

  # Client.close_event raises an InvalidTimeError if the stop time is not in
  # UTC.
  def test_close_event_with_non_utc_stop_time
    stop_time = Time.new(2013, 1, 12, 15, 25, 0, '+09:00')
    error = assert_raises Vault::Usage::Client::InvalidTimeError do
      @client.close_event(@event_id, @product_name, @app_id, stop_time)
    end
    assert_equal('Stop time must be in UTC.', error.message)
  end

  # Client.close_event raises the appropriate Excon::Errors::HTTPStatusError
  # if an unsuccessful HTTP status code is returned by the server.
  def test_close_event_with_unsuccessful_response
    Excon.stub(method: :post) do |request|
      Excon.stubs.pop
      {status: 400, body: 'Bad inputs provided.'}
    end
    assert_raises Excon::Errors::BadRequest do
      @client.close_event(@event_id, @product_name, @app_id, @stop_time)
    end
  end

  # Client.usage_for_user makes a GET request to the Vault::Usage HTTP API,
  # passing the supplied credentials using HTTP basic auth, to retrieve the
  # usage events for a particular user that occurred during the specified
  # period of time.
  def test_usage_for_user
    Excon.stub(method: :get) do |request|
      assert_equal('Basic dXNlcm5hbWU6c2VjcmV0',
                   request[:headers]['Authorization'])
      assert_equal('vault-usage.herokuapp.com:443', request[:host_port])
      assert_equal("/users/#{@user_id}/usage/#{iso_format(@start_time)}/" +
                   "#{iso_format(@stop_time)}",
                   request[:path])
      Excon.stubs.pop
      {status: 200, body: JSON.generate([])}
    end
    assert_equal([], @client.usage_for_user(@user_id, @start_time, @stop_time))
  end

  # Client.usage_for_user optionally accepts a list of products to exclude.
  # They're passed to the server using query string arguments.
  def test_usage_for_user_with_exclude
    Excon.stub(method: :get) do |request|
      assert_equal({exclude: 'platform:dyno:physical'}, request[:query])
      Excon.stubs.pop
      {status: 200, body: JSON.generate([])}
    end
    assert_equal([], @client.usage_for_user(@user_id, @start_time, @stop_time,
                                            ['platform:dyno:physical']))
  end

  # Client.usage_for_user comma-separates product names, when many are
  # provided in the exclusion list, and passes them to the server using a
  # single query argument.
  def test_usage_for_user_with_many_excludes
    Excon.stub(method: :get) do |request|
      assert_equal({exclude: 'platform:dyno:physical,addons:memcache:100mb'},
                   request[:query])
      Excon.stubs.pop
      {status: 200, body: JSON.generate([])}
    end
    assert_equal([], @client.usage_for_user(@user_id, @start_time, @stop_time,
                                            ['platform:dyno:physical',
                                             'addons:memcache:100mb']))
  end

  # Client.usage_for_user with an empty product exclusion list is the same as
  # not passing one at all.
  def test_usage_for_user_with_empty_exclude
    Excon.stub(method: :get) do |request|
      assert_equal(nil, request[:query])
      Excon.stubs.pop
      {status: 200, body: JSON.generate([])}
    end
    assert_equal([], @client.usage_for_user(@user_id, @start_time, @stop_time,
                                            []))
  end

  # Client.usage_for_user converts event start and stop times to Time
  # instances.
  def test_usage_for_user_converts_times
    Excon.stub(method: :get) do |request|
      Excon.stubs.pop
      events = [{id: @event_id,
                 product: @product_name,
                 consumer: @app_id,
                 start_time: iso_format(@start_time),
                 stop_time: iso_format(@stop_time),
                 detail: {}}]
      {status: 200, body: JSON.generate(events)}
    end
    assert_equal([{id: @event_id,
                   product: @product_name,
                   consumer: @app_id,
                   start_time: @start_time,
                   stop_time: @stop_time,
                   detail: {}}],
                 @client.usage_for_user(@user_id, @start_time, @stop_time))
  end

  # Client.usage_for_user raises an InvalidTimeError if the start time is not
  # in UTC.
  def test_usage_for_user_with_non_utc_start_time
    start_time = Time.new(2013, 1, 12, 15, 25, 0, '+09:00')
    error = assert_raises Vault::Usage::Client::InvalidTimeError do
      @client.usage_for_user(@user_id, start_time, @stop_time)
    end
    assert_equal('Start time must be in UTC.', error.message)
  end

  # Client.usage_for_user raises an InvalidTimeError if the stop time is not
  # in UTC.
  def test_usage_for_user_with_non_utc_stop_time
    stop_time = Time.new(2013, 1, 12, 15, 25, 0, '+09:00')
    error = assert_raises Vault::Usage::Client::InvalidTimeError do
      @client.usage_for_user(@user_id, @start_time, stop_time)
    end
    assert_equal('Stop time must be in UTC.', error.message)
  end

  # Client.usage_for_user raises the appropriate Excon::Errors::HTTPStatusError
  # if an unsuccessful HTTP status code is returned by the server.
  def test_usage_for_user_with_unsuccessful_response
    Excon.stub(method: :get) do |request|
      Excon.stubs.pop
      {status: 400, body: 'Bad inputs provided.'}
    end
    assert_raises Excon::Errors::BadRequest do
      @client.usage_for_user(@user_id, @start_time, @stop_time)
    end
  end
end
