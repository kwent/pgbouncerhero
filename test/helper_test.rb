require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include PgBouncerHero::ApplicationHelper

  def test_alert_class_for_success
    assert_equal "success", alert_class_for("success")
  end

  def test_alert_class_for_error
    assert_equal "error", alert_class_for("error")
  end

  def test_alert_class_for_notice
    assert_equal "info", alert_class_for("notice")
  end

  def test_alert_class_for_unknown
    assert_nil alert_class_for("unknown")
  end

  def test_alert_style_for_success
    assert_includes alert_style_for("success"), "bg-green-50"
  end

  def test_alert_style_for_error
    assert_includes alert_style_for("error"), "bg-red-50"
  end

  def test_humanize_ms
    result = humanize_ms(61_001)
    assert_includes result, "min"
    assert_includes result, "s"
    assert_includes result, "ms"
  end

  def test_fleet_health_marks_missing_summary_offline
    assert_equal "offline", fleet_health(nil).fetch(:status)
    assert_equal 3, fleet_health(nil).fetch(:severity)
  end

  def test_fleet_health_prioritizes_waiting_clients
    health = fleet_health(summary(waiting: 3, current: 9, maximum: 10))

    assert_equal "waiting", health.fetch(:status)
    assert_equal 2, health.fetch(:severity)
    assert_equal 3, health.fetch(:waiting_clients)
    assert_equal 90, health.fetch(:max_utilization)
  end

  def test_fleet_health_marks_high_utilization
    health = fleet_health(summary(waiting: 0, current: 8, maximum: 10))

    assert_equal "high_utilization", health.fetch(:status)
    assert_equal 1, health.fetch(:severity)
  end

  def test_fleet_health_marks_normal_utilization_healthy
    health = fleet_health(summary(waiting: 0, current: 7, maximum: 10))

    assert_equal "healthy", health.fetch(:status)
    assert_equal 0, health.fetch(:severity)
  end

  private

  def summary(waiting:, current:, maximum:)
    [
      { pools_details: [ { "cl_waiting" => waiting.to_s } ] },
      { databases_details: [ { "current_connections" => current.to_s, "max_connections" => maximum.to_s } ] }
    ]
  end
end
