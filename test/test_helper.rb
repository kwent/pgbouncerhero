ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "minitest/autorun"

# Released Rails versions pass options that JSON 3 no longer accepts. These
# overrides mirror the fixes already backported upstream to the stable branches.
# https://github.com/rails/rails/commit/59c76d2610cc0c086678f7ef0b0a475aca80e73e
# https://github.com/rails/rails/pull/58601
if Gem::Version.new(JSON::VERSION) >= Gem::Version.new("3")
  module Json3ActiveSupportCompatibility
    module Decoding
      def decode(json, options = {})
        data = ::JSON.parse(json, **options)

        if ActiveSupport.parse_json_times
          convert_dates_from(data)
        else
          data
        end
      end
    end

    module Encoding
      private
        def stringify(jsonified)
          ::JSON.generate(jsonified)
        end
    end
  end

  ActiveSupport::JSON.singleton_class.prepend(Json3ActiveSupportCompatibility::Decoding)
  ActiveSupport::JSON::Encoding::JSONGemEncoder.prepend(Json3ActiveSupportCompatibility::Encoding)
end

module AdminCommandEventTestHelper
  def capture_admin_command_events
    events = []
    subscriber = ActiveSupport::Notifications.subscribe(PgBouncerHero::ADMIN_COMMAND_EVENT) do |*arguments|
      events << ActiveSupport::Notifications::Event.new(*arguments)
    end

    yield
    events
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end

Minitest::Test.include(AdminCommandEventTestHelper)
