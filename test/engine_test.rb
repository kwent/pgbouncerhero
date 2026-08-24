require "test_helper"
require "tmpdir"

class EngineTest < ActionDispatch::IntegrationTest
  def test_dashboard_renders
    get "/pgbouncerhero"

    assert_response :success
    assert_select "h2", "Overview"
    assert_select "turbo-frame", count: 1
  end

  def test_unknown_group_does_not_match
    get "/pgbouncerhero/unknown/primary/stats"

    assert_response :not_found
  end

  def test_parameterized_group_and_database_names_route_correctly
    with_config(<<~YAML) do
      pgbouncers:
        My Group:
          Read Replica: {}
    YAML
      get "/pgbouncerhero/my-group/read-replica/databases"

      assert_response :success
      assert_select "span", "My Group > Read Replica"
    end
  end

  private

  def with_config(contents)
    previous_path = PgBouncerHero.instance_variable_get(:@config_path)

    Dir.mktmpdir do |directory|
      path = Pathname(directory).join("pgbouncerhero.yml")
      path.write(contents)
      PgBouncerHero.config_path = path
      yield
    end
  ensure
    PgBouncerHero.config_path = previous_path
  end
end
