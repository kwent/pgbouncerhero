require "test_helper"

class DatabaseTest < Minitest::Test
  FakeConnection = Struct.new(:status, :finished, :finish_calls) do
    def initialize(status: PG::CONNECTION_OK, finished: false)
      super(status, finished, 0)
    end

    def finished?
      finished
    end

    def finish
      self.finish_calls += 1
      self.finished = true
    end
  end

  def setup
    config = {
      "test_group" => {
        "primary" => {
          "url" => "postgres://user:pass@localhost:6432/pgbouncer"
        }
      }
    }
    @group = PgBouncerHero::Group.new("test_group", config)
    @database = @group.databases.first
  end

  def test_database_name
    assert_equal "primary", @database.name
  end

  def test_database_host
    assert_equal "localhost", @database.host
  end

  def test_database_port
    assert_equal 6432, @database.port
  end

  def test_database_user
    assert_equal "user", @database.user
  end

  def test_database_dbname
    assert_equal "pgbouncer", @database.dbname
  end

  def test_database_with_nil_url
    config = { "test_group" => { "primary" => {} } }
    group = PgBouncerHero::Group.new("test_group", config)
    database = group.databases.first

    assert_nil database.host
    assert_nil database.port
    assert_nil database.connection
  end

  def test_database_with_empty_url
    config = { "test_group" => { "primary" => { "url" => "" } } }
    group = PgBouncerHero::Group.new("test_group", config)
    database = group.databases.first

    assert_nil database.host
    assert_nil database.port
    assert_nil database.connection
  end

  def test_connection_reuses_a_valid_connection
    connection = FakeConnection.new
    @database.instance_variable_set(:@connection, connection)

    assert_same connection, @database.connection
  end

  def test_connection_replaces_a_connection_with_a_bad_status
    stale_connection = FakeConnection.new(status: PG::CONNECTION_BAD)
    replacement_connection = FakeConnection.new
    @database.instance_variable_set(:@connection, stale_connection)

    stub_connection_model(replacement_connection)

    assert_same replacement_connection, @database.connection
    assert_predicate stale_connection, :finished?
    assert_equal 1, stale_connection.finish_calls
  end

  def test_connection_replaces_a_finished_connection
    stale_connection = FakeConnection.new(finished: true)
    replacement_connection = FakeConnection.new
    @database.instance_variable_set(:@connection, stale_connection)

    stub_connection_model(replacement_connection)

    assert_same replacement_connection, @database.connection
    assert_equal 0, stale_connection.finish_calls
  end

  def test_disconnect_closes_and_clears_the_connection
    connection = FakeConnection.new
    @database.instance_variable_set(:@connection, connection)

    @database.disconnect!

    assert_predicate connection, :finished?
    assert_nil @database.instance_variable_get(:@connection)
  end

  private

  def stub_connection_model(connection)
    connection_model = Class.new do
      define_method(:initialize) { |*| }
      define_method(:connection) { connection }
    end
    @database.define_singleton_method(:connection_model) { connection_model }
  end
end
