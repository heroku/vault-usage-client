module Vault::Usage::Client
  class Client
    # Instantiate a client.
    #
    # @param username [String] The username to pass to Vault::Usage in HTTP
    #   basic auth credentials.
    # @param password [String] The password to pass to Vault::Usage in HTTP
    #   basic auth credentials.
    def initialize(username, password)
      @username = username
      @password = password
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
    # @param start_time [Time] The beginning of the usage period.
    # @param detail [Hash] Optionally, additional details to store with the
    #   event.
    def open_event(event_id, product_name, heroku_id, start_time, detail=nil)
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
    # @param stop_time [Time] The end of the usage period.
    def close_event(event_id, product_name, heroku_id, stop_time)
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
  end
end
