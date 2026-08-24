require "test_helper"
require "tmpdir"

class PgBouncerHeroTest < Minitest::Test
  def test_version
    assert PgBouncerHero::VERSION
    assert_equal "3.0.0", PgBouncerHero::VERSION
  end

  def test_config_returns_hash
    assert_kind_of Hash, PgBouncerHero.config
  end

  def test_config_has_pgbouncers_key
    assert PgBouncerHero.config.key?("pgbouncers")
  end

  def test_config_path_defaults_to_the_host_application
    assert_equal Rails.root.join("config/pgbouncerhero.yml"), PgBouncerHero.config_path
  end

  def test_config_loads_the_current_environment_from_a_custom_path
    with_config(<<~YAML) do
      test:
        pgbouncers:
          local:
            primary:
              url: postgres://user:pass@localhost:6432/pgbouncer
    YAML
      assert_equal [ "local" ], PgBouncerHero.groups.keys
      assert_equal "localhost", PgBouncerHero.groups.fetch("local").databases.first.host
    end
  end

  def test_config_rejects_a_non_mapping_document
    with_config("- invalid\n") do
      error = assert_raises(PgBouncerHero::ConfigurationError) { PgBouncerHero.config }

      assert_includes error.message, "must contain a YAML mapping"
    end
  end

  def test_config_rejects_empty_pgbouncer_groups
    with_config("pgbouncers: {}\n") do
      error = assert_raises(PgBouncerHero::ConfigurationError) { PgBouncerHero.config }

      assert_includes error.message, "must contain at least one group"
    end
  end

  def test_read_only_mode_uses_configuration
    with_config(<<~YAML) do
      read_only: true
      pgbouncers:
        local:
          primary: {}
    YAML
      assert_predicate PgBouncerHero, :read_only?
    end
  end

  def test_read_only_environment_setting_overrides_configuration
    with_config(<<~YAML) do
      read_only: true
      pgbouncers:
        local:
          primary: {}
    YAML
      ENV["PGBOUNCERHERO_READ_ONLY"] = "off"

      refute_predicate PgBouncerHero, :read_only?
    ensure
      ENV.delete("PGBOUNCERHERO_READ_ONLY")
    end
  end

  def test_read_only_mode_rejects_invalid_values
    ENV["PGBOUNCERHERO_READ_ONLY"] = "sometimes"

    error = assert_raises(PgBouncerHero::ConfigurationError) { PgBouncerHero.read_only? }

    assert_equal "read_only must be a boolean", error.message
  ensure
    ENV.delete("PGBOUNCERHERO_READ_ONLY")
  end

  def test_groups_returns_hash
    ENV["PGBOUNCERHERO_DATABASE_URL"] = "postgres://user:pass@localhost:6432/pgbouncer"
    PgBouncerHero.reset!
    assert_kind_of Hash, PgBouncerHero.groups
    assert PgBouncerHero.groups.key?("default")
  ensure
    ENV.delete("PGBOUNCERHERO_DATABASE_URL")
    PgBouncerHero.reset!
  end

  def test_disconnect_closes_initialized_database_connections
    disconnected = false
    database = Object.new
    database.define_singleton_method(:disconnect!) { disconnected = true }
    group = Struct.new(:databases).new([ database ])
    previous_groups = PgBouncerHero.instance_variable_get(:@groups)
    PgBouncerHero.instance_variable_set(:@groups, { "test" => group })

    PgBouncerHero.disconnect!

    assert disconnected
  ensure
    PgBouncerHero.instance_variable_set(:@groups, previous_groups)
  end

  def test_importmap_exists
    assert_kind_of Importmap::Map, PgBouncerHero.importmap
  end

  private

  def with_config(contents)
    previous_path = PgBouncerHero.instance_variable_get(:@config_path)
    previous_env = PgBouncerHero.env

    Dir.mktmpdir do |directory|
      path = Pathname(directory).join("pgbouncerhero.yml")
      path.write(contents)
      PgBouncerHero.config_path = path
      PgBouncerHero.env = "test"
      yield
    end
  ensure
    PgBouncerHero.config_path = previous_path
    PgBouncerHero.env = previous_env
  end
end
