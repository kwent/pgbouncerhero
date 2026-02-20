require "test_helper"

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

  def test_groups_returns_hash
    ENV["PGBOUNCERHERO_DATABASE_URL"] = "postgres://user:pass@localhost:6432/pgbouncer"
    PgBouncerHero.instance_variable_set(:@config, nil)
    PgBouncerHero.instance_variable_set(:@groups, nil)
    assert_kind_of Hash, PgBouncerHero.groups
    assert PgBouncerHero.groups.key?("default")
  ensure
    ENV.delete("PGBOUNCERHERO_DATABASE_URL")
    PgBouncerHero.instance_variable_set(:@config, nil)
    PgBouncerHero.instance_variable_set(:@groups, nil)
  end

  def test_importmap_exists
    assert_kind_of Importmap::Map, PgBouncerHero.importmap
  end
end
