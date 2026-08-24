require "test_helper"

class ConnectionTest < Minitest::Test
  class FakeRawConnection
    attr_accessor :status
    attr_reader :finish_calls, :queries

    def initialize(status: PG::CONNECTION_OK, finished: false, error: nil)
      @status = status
      @finished = finished
      @error = error
      @finish_calls = 0
      @queries = []
    end

    def finished?
      @finished
    end

    def finish
      @finish_calls += 1
      @finished = true
    end

    def exec(query)
      raise @error if @error

      @queries << query
      []
    end
  end

  def test_connection_returns_nil_on_failure
    connection = build_connection(PG::ConnectionBad.new("unavailable"))

    assert_nil connection.connection
  end

  def test_connection_reuses_a_valid_connection
    raw_connection = FakeRawConnection.new
    connection = build_connection(raw_connection)

    assert_same raw_connection, connection.connection
    assert_same raw_connection, connection.connection
  end

  def test_connection_replaces_a_finished_connection
    stale_connection = FakeRawConnection.new(finished: true)
    replacement_connection = FakeRawConnection.new
    connection = build_connection(stale_connection, replacement_connection)

    assert_same stale_connection, connection.connection
    assert_same replacement_connection, connection.connection
  end

  def test_connection_replaces_a_connection_with_a_bad_status
    stale_connection = FakeRawConnection.new(status: PG::CONNECTION_BAD)
    replacement_connection = FakeRawConnection.new
    connection = build_connection(stale_connection, replacement_connection)

    assert_same stale_connection, connection.connection
    assert_same replacement_connection, connection.connection
    assert_equal 1, stale_connection.finish_calls
  end

  def test_disconnect_closes_the_connection
    raw_connection = FakeRawConnection.new
    connection = build_connection(raw_connection)
    connection.connection

    connection.disconnect!

    assert_predicate raw_connection, :finished?
    assert_nil connection.instance_variable_get(:@connection)
  end

  def test_delegates_methods_to_the_raw_connection
    raw_connection = FakeRawConnection.new
    connection = build_connection(raw_connection)

    connection.exec("SHOW stats")

    assert_equal [ "SHOW stats" ], raw_connection.queries
    assert_equal PG::CONNECTION_OK, connection.status
  end

  def test_discards_a_connection_after_a_pg_error
    stale_connection = FakeRawConnection.new(error: PG::ConnectionBad.new("lost"))
    replacement_connection = FakeRawConnection.new
    connection = build_connection(stale_connection, replacement_connection)

    assert_raises(PG::ConnectionBad) { connection.exec("SHOW stats") }
    assert_predicate stale_connection, :finished?
    assert_same replacement_connection, connection.connection
  end

  private

  def build_connection(*connections)
    remaining_connections = connections.dup
    model = Class.new(PgBouncerHero::Connection) do
      define_method(:connect) do
        candidate = remaining_connections.shift
        raise candidate if candidate.is_a?(Exception)

        candidate
      end
    end
    model.new("localhost", 6432, "user", "password", "pgbouncer")
  end
end
