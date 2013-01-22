module Vault::Usage
  # Client for the `Vault::Usage` HTTP API.
  class Client
    attr_reader :url

    # Raised if a non-UTC time is used with the client.
    class InvalidTimeError < Exception
    end

    # Instantiate a client.
    #
    # @param url [String] The URL to connect to.  Include the username and
    #   password to use when connecting.
    def initialize(url = nil)
      @url = url || ENV['VAULT_USAGE_URL']
    end

    # Report that usage of a product, by a user or app, started at a
    # particular time.
    #
    # @param event_id [String] A UUID that uniquely identifies the usage
    #   event.
    # @param product_name [String] The name of the product that was used, such
    #   as `platform:dyno:logical` or `addon:memcache:100mb`.
    # @param consumer_hid [String] The Heroku ID, such as `app1234@heroku.com`
    #   or `user1234@heroku.com`, that represents the user or app that used
    #   the specified product.
    # @param start_time [Time] The beginning of the usage period, always in
    #   UTC.
    # @param detail [Hash] Optionally, additional details to store with the
    #   event.  Keys must be of type `Symbol` and values may only be of type
    #   `String`, `Fixnum`, `Bignum`, `Float`, `TrueClass`, `FalseClass` or
    #   `NilClass`.
    # @raise [InvalidTimeError] Raised if a non-UTC start time is provided.
    # @raise [Excon::Errors::HTTPStatusError] Raised if the server returns an
    #   unsuccessful HTTP status code.
    def open_usage_event(event_id, product_name, consumer_hid, start_time,
                         detail=nil)
      unless start_time.zone.eql?('UTC')
        raise InvalidTimeError.new('Start time must be in UTC.')
      end
      path = "/products/#{product_name}/usage/#{consumer_hid}" +
             "/events/#{event_id}/open/#{iso_format(start_time)}"
      unless detail.nil?
        headers = {'Content-Type' => 'application/json'}
        body = JSON.generate(detail)
      end
      connection = Excon.new(@url)
      connection.post(path: path, headers: headers, body: body,
                      expects: [200])
    end

    # Report that usage of a product, by a user or app, stopped at a
    # particular time.
    #
    # @param event_id [String] A UUID that uniquely identifies the usage
    #   event.
    # @param product_name [String] The name of the product that was used, such
    #   as `platform:dyno:logical` or `addon:memcache:100mb`.
    # @param consumer_hid [String] The Heroku ID, such as `app1234@heroku.com`
    #   or `user1234@heroku.com`, that represents the user or app that used
    #   the specified product.
    # @param stop_time [Time] The end of the usage period, always in UTC.
    # @raise [InvalidTimeError] Raised if a non-UTC stop time is provided.
    # @raise [Excon::Errors::HTTPStatusError] Raised if the server returns an
    #   unsuccessful HTTP status code.
    def close_usage_event(event_id, product_name, consumer_hid, stop_time)
      unless stop_time.zone.eql?('UTC')
        raise InvalidTimeError.new('Stop time must be in UTC.')
      end
      path = "/products/#{product_name}/usage/#{consumer_hid}" +
             "/events/#{event_id}/close/#{iso_format(stop_time)}"
      connection = Excon.new(@url)
      connection.post(path: path, expects: [200])
    end

    # Get the usage events for the apps owned by the specified user during the
    # specified period.
    #
    # @param user_hid [String] The user HID, such as `user1234@heroku.com`, to
    #   fetch usage data for.
    # @param start_time [Time] The beginning of the usage period, always in
    #   UTC, within which events must overlap to be included in usage data.
    # @param stop_time [Time] The end of the usage period, always in UTC,
    #   within which events must overlap to be included in usage data.
    # @param exclude [Array] Optionally, a list of product names, such as
    #   `['platform:dyno:physical', 'addon:memcache:100mb']`, to be excluded
    #   from usage data.
    # @raise [InvalidTimeError] Raised if a non-UTC start or stop time is
    #   provided.
    # @raise [Excon::Errors::HTTPStatusError] Raised if the server returns an
    #   unsuccessful HTTP status code.
    # @return [Array] A list of usage events for the specified user, matching
    #   the following format:
    #
    #   ```
    #     [{id: '<event-uuid>',
    #       product: '<name>',
    #       consumer: '<heroku-id>',
    #       start_time: <Time>,
    #       stop_time: <Time>,
    #       detail: {<key1>: <value1>,
    #                <key2>: <value2>,
    #                ...}},
    #       ...]}
    #   ```
    def usage_for_user(user_hid, start_time, stop_time, exclude=nil)
      unless start_time.zone.eql?('UTC')
        raise InvalidTimeError.new('Start time must be in UTC.')
      end
      unless stop_time.zone.eql?('UTC')
        raise InvalidTimeError.new('Stop time must be in UTC.')
      end
      path = "/users/#{user_hid}/usage/#{iso_format(start_time)}/" +
             "#{iso_format(stop_time)}"
      unless exclude.nil? || exclude.empty?
        query = {exclude: exclude.join(',')}
      end
      connection = Excon.new(@url)
      response = connection.get(path: path, expects: [200], query: query)
      events = JSON.parse(response.body, {symbolize_keys: true})
      events.each do |event|
        event.each do |key, value|
          event[key] = parse_date(value) if date?(value)
        end
      end
    end

    # Report that ownership of an app by a user started at a particular time.
    #
    # @param event_id [String] A UUID that uniquely identifies the ownership
    #   event.
    # @param user_hid [String] The user HID, such as `user1234@heroku.com`,
    #   that owns the specified app.
    # @param app_hid [String] The app HID, such as `app1234@heroku.com`, that
    #   is being transferred to the specified user.
    # @param start_time [Time] The beginning of the ownership period, always
    #   in UTC.
    # @raise [InvalidTimeError] Raised if a non-UTC start time is provided.
    # @raise [Excon::Errors::HTTPStatusError] Raised if the server returns an
    #   unsuccessful HTTP status code.
    def open_app_ownership_event(event_id, user_hid, app_hid, start_time)
      unless start_time.zone.eql?('UTC')
        raise InvalidTimeError.new('Start time must be in UTC.')
      end
      path = "/users/#{user_hid}/apps/#{app_hid}/open/#{event_id}" +
             "/#{iso_format(start_time)}"
      connection = Excon.new(@url)
      connection.post(path: path, expects: [200])
    end

    # Report that ownership of an app by a user stopped at a particular time.
    #
    # @param event_id [String] A UUID that uniquely identifies the ownership
    #   event.
    # @param user_hid [String] The user HID, such as `user1234@heroku.com`,
    #   that owned the specified app.
    # @param app_hid [String] The app HID, such as `app1234@heroku.com`, that
    #   is being transferred away from the specified user.
    # @param stop_time [Time] The end of the ownership period, always in UTC.
    # @raise [InvalidTimeError] Raised if a non-UTC stop time is provided.
    # @raise [Excon::Errors::HTTPStatusError] Raised if the server returns an
    #   unsuccessful HTTP status code.
    def close_app_ownership_event(event_id, user_hid, app_hid, stop_time)
      unless stop_time.zone.eql?('UTC')
        raise InvalidTimeError.new('Stop time must be in UTC.')
      end
      path = "/users/#{user_hid}/apps/#{app_hid}/close/#{event_id}" +
             "/#{iso_format(stop_time)}"
      connection = Excon.new(@url)
      connection.post(path: path, expects: [200])
    end

    private

    # Convert a time to an ISO 8601 combined data and time format.
    #
    # @param time [Time] The time to convert to ISO 8601 format.
    # @return [String] An ISO 8601 date in `YYYY-MM-DDTHH:MM:SSZ` format.
    def iso_format(time)
      time.strftime('%Y-%m-%dT%H:%M:%SZ')
    end

    # Determine if the value is an ISO 8601 date in `YYYY-MM-DDTHH:MM:SSZ`
    # format.
    #
    # @param value [String] The value to check for date-ness.
    # @return [TrueClass,FalseClass] True if the value resembles a date,
    #   otherwise false.
    def date?(value)
      value =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
    end

    # Parse an ISO 8601 date in `YYYY-MM-DDTHH:MM:SSZ` format into a Time
    # instance.
    #
    # @param value [String] The value to parse.
    # @raise [ArgumentError] Raised if the value doesn't represent a valid
    #   date.
    # @return [Time] The Time instance created from the date string in UTC.
    def parse_date(value)
      DateTime.parse(value).to_time.getutc
    end
  end
end
