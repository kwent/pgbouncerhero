require "test_helper"

class GroupTest < Minitest::Test
  def test_group_has_databases
    config = {
      "test_group" => {
        "primary" => {
          "url" => "postgres://user:pass@localhost:6432/pgbouncer"
        }
      }
    }
    group = PgBouncerHero::Group.new("test_group", config)
    assert_equal 1, group.databases.size
    assert_equal "primary", group.databases.first.name
  end

  def test_group_name
    config = { "my_group" => { "primary" => { "url" => "postgres://u:p@h:6432/pgbouncer" } } }
    group = PgBouncerHero::Group.new("my_group", config)
    assert_equal "my_group", group.name
  end
end
