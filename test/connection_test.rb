require "test_helper"

class ConnectionTest < Minitest::Test
  def test_connection_returns_nil_on_failure
    conn = PgBouncerHero::Connection.new("localhost", 99999, "nobody", "nopass", "noexist")
    assert_nil conn.connection
  end
end
