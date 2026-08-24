require "test_helper"

class PgBouncerIntegrationTest < Minitest::Test
  URL = ENV.fetch(
    "PGBOUNCERHERO_INTEGRATION_URL",
    "postgres://pgbouncer:pgbouncer@127.0.0.1:6432/pgbouncer"
  )

  def setup
    config = {
      "integration" => {
        "primary" => { "url" => URL }
      }
    }
    @database = PgBouncerHero::Group.new("integration", config).databases.first
  end

  def teardown
    @database.disconnect!
  end

  def test_connects_to_the_pgbouncer_admin_console
    result = @database.connection.exec("SHOW VERSION")

    assert_match(/\APgBouncer \d+\.\d+\.\d+/, result.first.fetch("version"))
    assert_equal PG::CONNECTION_OK, @database.connection.status
  end

  def test_executes_dashboard_queries_against_pgbouncer
    results = {
      databases: @database.databases,
      stats: @database.stats,
      lists: @database.lists,
      pools: @database.pools,
      clients: @database.clients,
      config: @database.conf
    }

    results.each_value { |result| assert_instance_of PG::Result, result }
    assert_includes results.fetch(:databases).map { |row| row.fetch("name") }, "app"
    assert_includes results.fetch(:config).map { |row| row.fetch("key") }, "listen_port"
  end

  def test_builds_a_summary_from_real_results
    summary = @database.summary
    database_details = summary.find { |row| row.key?(:databases_details) }

    assert database_details
    assert_includes database_details.fetch(:databases_details).map { |row| row.fetch("name") }, "app"
    refute_includes database_details.fetch(:databases_details).map { |row| row.fetch("name") }, "pgbouncer"
  end

  def test_reconnects_after_the_connection_is_finished
    original = @database.connection
    original.finish

    replacement = @database.connection

    refute_same original, replacement
    assert_equal PG::CONNECTION_OK, replacement.status
  end

  def test_reload_keeps_the_admin_console_available
    result = @database.reload

    assert_equal PG::PGRES_COMMAND_OK, result.result_status
    assert_instance_of PG::Result, @database.stats
  end

  def test_rejects_invalid_credentials
    invalid_url = URI(URL).dup
    invalid_url.password = "incorrect"
    config = { "integration" => { "invalid" => { "url" => invalid_url.to_s } } }
    database = PgBouncerHero::Group.new("integration", config).databases.first

    assert_nil database.connection
  ensure
    database&.disconnect!
  end
end
