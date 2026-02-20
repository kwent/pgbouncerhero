require "test_helper"

class DatabaseTest < Minitest::Test
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
end
