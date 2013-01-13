module Vault::Usage::Client
  # Raised if a non-UTC time is used with the client.
  class InvalidTimeError < Exception
  end

  class Client
    # Instantiate a client.
    #
    # @param username [String] The username to pass to Vault::Usage in HTTP
    #   basic auth credentials.
    # @param password [String] The password to pass to Vault::Usage in HTTP
    #   basic auth credentials.
    # @param host [String] Optionally, the hostname to connect to.  Defaults
    #   to `https://vault-usage.herokuapp.com`.
    def initialize(username, password, host=nil)
      @username = username
      @password = password
      @connection = Excon.new(host || 'https://vault-usage.herokuapp.com')
    end

    # Report that usage of a product, by a user or app, started at a
    # particular time.
    #
    # @param event_id [String] A UUID that uniquely identifies the usage
    #   event.
    # @param product_name [String] The name of the product that was used, such
    #   as `platform:dyno:logical` or `addon:memcache:100mb`.
    # @param heroku_id [String] The Heroku ID, such as `app1234@heroku.com`,
    #   that represents the user or app that used the specified product.
    # @param start_time [Time] The beginning of the usage period, always in
    #   UTC.
    # @param detail [Hash] Optionally, additional details to store with the
    #   event.
    # @raise [InvalidTimeError] Raised if a non-UTC start time is provided.
    # @raise [Excon::Errors::HTTPStatusError] Raised if the server returns an
    #   unsuccessful HTTP status code.
    def open_event(event_id, product_name, heroku_id, start_time, detail=nil)
      unless start_time.zone.eql?('UTC')
        raise InvalidTimeError.new('Start time must be in UTC.')
      end
      path = "/products/#{product_name}/usage/#{heroku_id}" +
             "/events/#{event_id}/open/#{iso_format(start_time)}"
      unless detail.nil?
        headers = {'Content-Type' => 'application/json'}
        body = Yajl::Encoder.encode(detail)
      end
      @connection.post(path: path, headers: headers, body: body,
                       expects: [200])
    end

    # Report that usage of a product, by a user or app, stopped at a
    # particular time.
    #
    # @param event_id [String] A UUID that uniquely identifies the usage
    #   event.
    # @param product_name [String] The name of the product that was used, such
    #   as `platform:dyno:logical` or `addon:memcache:100mb`.
    # @param heroku_id [String] The Heroku ID, such as `app1234@heroku.com`,
    #   that represents the user or app that used the specified product.
    # @param stop_time [Time] The end of the usage period, always in UTC.
    # @raise [InvalidTimeError] Raised if a non-UTC stop time is provided.
    # @raise [Excon::Errors::HTTPStatusError] Raised if the server returns an
    #   unsuccessful HTTP status code.
    def close_event(event_id, product_name, heroku_id, stop_time)
      unless stop_time.zone.eql?('UTC')
        raise InvalidTimeError.new('Stop time must be in UTC.')
      end
      path = "/products/#{product_name}/usage/#{heroku_id}" +
             "/events/#{event_id}/open/#{iso_format(stop_time)}"
      @connection.post(path: path, expects: [200])
    end

    # Get the usage events for the apps owned by the specified user during the
    # specified period.
    #
    # @param user_id [String] The user ID, such as `user1234@heroku.com`, to
    #   fetch usage data for.
    # @param start_time [Time] The beginning of the usage period, always in
    #   UTC, within which events must overlap to be included in usage data.
    # @param stop_time [Time] The end of the usage period, always in UTC,
    #   within which events must overlap to be included in usage data.
    # @return [Array] A list of usage events for the specified user, matching
    #   the following format:
    #
    #   ```
    #     [{id: '<event-uuid>',
    #        product: '<name>',
    #        consumer: '<heroku-id>',
    #        start_time: '<Time>',
    #        stop_time: '<Time>',
    #        detail: {<key1>: <value1>,
    #                 <key2>: <value2>,
    #                 ...}},
    #       ...]}
    #   ```
    def usage_for_user(user_id, start_time, stop_time)
    end

    private

    # Convert a time to an ISO 8601 combined data and time format.
    #
    # @param time [Time] The time to convert to ISO 8601 format.
    # @return [String] An ISO 8601 date in `YYYY-MM-DDTHH:MM:SSZ` format.
    def iso_format(time)
      time.strftime('%Y-%m-%dT%H:%M:%SZ')
    end
  end
end
