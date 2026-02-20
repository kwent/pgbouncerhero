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
end
