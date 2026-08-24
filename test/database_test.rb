require "test_helper"

class DatabaseTest < Minitest::Test
  class FakeConnection
    attr_reader :finish_calls, :queries

    def initialize(tracker: nil)
      @tracker = tracker
      @finish_calls = 0
      @queries = []
      @finished = false
    end

    def status
      PG::CONNECTION_OK
    end

    def finished?
      @finished
    end

    def finish
      @finish_calls += 1
      @finished = true
    end

    def exec(query)
      @tracker&.enter
      sleep 0.02 if @tracker
      @queries << query
      []
    ensure
      @tracker&.leave
    end
  end

  class ConcurrencyTracker
    attr_reader :max_active

    def initialize
      @active = 0
      @max_active = 0
      @lock = Mutex.new
    end

    def enter
      @lock.synchronize do
        @active += 1
        @max_active = [ @max_active, @active ].max
      end
    end

    def leave
      @lock.synchronize { @active -= 1 }
    end
  end

  def setup
    @database = build_database
  end

  def test_database_attributes
    assert_equal "primary", @database.name
    assert_equal "localhost", @database.host
    assert_equal 6432, @database.port
    assert_equal "user", @database.user
    assert_equal "pgbouncer", @database.dbname
  end

  def test_database_with_nil_url
    database = build_database({})

    assert_nil database.host
    assert_nil database.port
    assert_nil database.connection
  end

  def test_database_with_nil_config
    database = build_database(nil)

    assert_nil database.host
    assert_nil database.connection
  end

  def test_database_with_empty_url
    database = build_database("url" => "")

    assert_nil database.host
    assert_nil database.port
    assert_nil database.connection
  end

  def test_pool_settings_use_database_config
    database = build_database("pool_size" => 3, "pool_timeout" => 0.25)

    assert_equal 3, database.pool_size
    assert_in_delta 0.25, database.pool_timeout
  end

  def test_pool_settings_must_be_positive
    error = assert_raises(ArgumentError) { build_database("pool_size" => 0) }

    assert_equal "pool_size must be greater than zero", error.message
  end

  def test_pool_settings_use_environment_defaults
    with_pool_environment("3", "0.25") do
      database = build_database

      assert_equal 3, database.pool_size
      assert_in_delta 0.25, database.pool_timeout
    end
  end

  def test_database_pool_settings_override_the_environment
    with_pool_environment("4", "0.5") do
      database = build_database("pool_size" => 2, "pool_timeout" => 0.1)

      assert_equal 2, database.pool_size
      assert_in_delta 0.1, database.pool_timeout
    end
  end

  def test_pool_timeout_must_be_finite
    error = assert_raises(ArgumentError) { build_database("pool_timeout" => Float::INFINITY) }

    assert_equal "pool_timeout must be a finite number greater than zero", error.message
  end

  def test_connection_returns_a_connection_compatible_proxy
    raw_connection = FakeConnection.new
    stub_connection_model(@database) { raw_connection }

    assert_equal PG::CONNECTION_OK, @database.connection.status
  end

  def test_with_connection_yields_a_raw_connection
    raw_connection = FakeConnection.new
    stub_connection_model(@database) { raw_connection }

    yielded_connection = @database.with_connection { |connection| connection }

    assert_same raw_connection, yielded_connection
  end

  def test_commands_reuse_idle_connections
    connections = []
    stub_connection_model(@database) { FakeConnection.new.tap { |connection| connections << connection } }

    2.times { @database.stats }

    assert_equal 1, connections.size
    assert_equal [ "SHOW stats", "SHOW stats" ], connections.first.queries
  end

  def test_admin_commands_use_supported_pgbouncer_syntax
    raw_connection = FakeConnection.new
    stub_connection_model(@database) { raw_connection }

    @database.state
    @database.reload
    @database.suspend
    @database.resume
    @database.shutdown
    @database.shutdown(:immediate)
    @database.shutdown(:wait_for_clients)
    @database.shutdown(:wait_for_servers)

    assert_equal [
      "SHOW state",
      "RELOAD",
      "SUSPEND",
      "RESUME",
      "SHUTDOWN",
      "SHUTDOWN",
      "SHUTDOWN WAIT_FOR_CLIENTS",
      "SHUTDOWN WAIT_FOR_SERVERS"
    ], raw_connection.queries
  end

  def test_shutdown_rejects_unknown_modes
    error = assert_raises(ArgumentError) { @database.shutdown(:eventually) }

    assert_equal "unsupported shutdown mode: :eventually", error.message
  end

  def test_commands_run_concurrently_up_to_the_pool_size
    tracker = ConcurrencyTracker.new
    database = build_database("pool_size" => 2)
    connections = []
    stub_connection_model(database) do
      FakeConnection.new(tracker: tracker).tap { |connection| connections << connection }
    end

    threads = 4.times.map { Thread.new { database.stats } }
    threads.each(&:join)

    assert_equal 2, tracker.max_active
    assert_equal 2, connections.size
    assert_equal 4, connections.sum { |connection| connection.queries.size }
  ensure
    database&.disconnect!
  end

  def test_pool_timeout_returns_nil
    database = build_database("pool_size" => 1, "pool_timeout" => 0.01)
    stub_connection_model(database) { FakeConnection.new }
    checked_out = Queue.new
    release = Queue.new
    holder = Thread.new do
      database.with_connection do
        checked_out << true
        release.pop
      end
    end
    checked_out.pop

    assert_nil database.stats
  ensure
    release&.push(true)
    holder&.join
    database&.disconnect!
  end

  def test_disconnect_closes_every_initialized_connection
    database = build_database("pool_size" => 2)
    connections = []
    stub_connection_model(database) { FakeConnection.new.tap { |connection| connections << connection } }
    checked_out = Queue.new
    release = Queue.new
    holders = 2.times.map do
      Thread.new do
        database.with_connection do
          checked_out << true
          release.pop
        end
      end
    end
    2.times { checked_out.pop }
    2.times { release << true }
    holders.each(&:join)

    database.disconnect!

    assert_equal 2, connections.size
    assert connections.all?(&:finished?)
  end

  private

  def build_database(database_config = :default)
    database_config = { "url" => "postgres://user:pass@localhost:6432/pgbouncer" } if database_config == :default
    config = { "test_group" => { "primary" => database_config } }
    PgBouncerHero::Group.new("test_group", config).databases.first
  end

  def stub_connection_model(database, &factory)
    connection_model = Class.new(PgBouncerHero::Connection) do
      define_method(:connect, &factory)
    end
    database.define_singleton_method(:connection_model) { connection_model }
  end

  def with_pool_environment(size, timeout)
    previous_size = ENV["PGBOUNCERHERO_POOL_SIZE"]
    previous_timeout = ENV["PGBOUNCERHERO_POOL_TIMEOUT"]
    ENV["PGBOUNCERHERO_POOL_SIZE"] = size
    ENV["PGBOUNCERHERO_POOL_TIMEOUT"] = timeout
    yield
  ensure
    ENV["PGBOUNCERHERO_POOL_SIZE"] = previous_size
    ENV["PGBOUNCERHERO_POOL_TIMEOUT"] = previous_timeout
  end
end
