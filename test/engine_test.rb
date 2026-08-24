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

  def test_read_only_mode_hides_controls_and_blocks_admin_commands
    with_config(<<~YAML) do
      read_only: true
      pgbouncers:
        Operations:
          Primary: {}
    YAML
      get "/pgbouncerhero/operations/primary/state"

      assert_response :success
      assert_select "span", "Read-only"
      assert_select "form[action$='/reload']", count: 0
      assert_select "form[action$='/suspend']", count: 0
      assert_select "form[action$='/resume']", count: 0
      assert_select "form[action$='/shutdown']", count: 0

      authenticity_token = css_select("meta[name='csrf-token']").first["content"]
      post "/pgbouncerhero/operations/primary/reload", params: { authenticity_token: authenticity_token }

      assert_response :forbidden
      assert_equal "PgBouncerHero is configured as read-only.", response.body
    end
  end

  def test_writable_mode_renders_complete_admin_controls
    with_config(<<~YAML) do
      pgbouncers:
        Operations:
          Primary: {}
    YAML
      get "/pgbouncerhero/operations/primary/state"

      assert_response :success
      assert_select "form[action$='/reload']", count: 1
      assert_select "form[action$='/suspend']", count: 1
      assert_select "form[action$='/resume']", count: 1
      assert_select "form[action$='/shutdown']", count: 1
      assert_select "button", "Graceful shutdown"
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
