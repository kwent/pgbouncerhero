ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "minitest/autorun"

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
