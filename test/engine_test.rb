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

  def test_servers_page_renders_empty_state_and_active_navigation
    with_stubbed_database(:servers, []) do
      get "/pgbouncerhero/operations/primary/servers"

      assert_response :success
      assert_select "a.bg-gray-900", text: "Servers"
      assert_select "p", "No server connections."
    end
  end

  def test_users_page_renders_empty_state_and_active_navigation
    with_stubbed_database(:users, []) do
      get "/pgbouncerhero/operations/primary/users"

      assert_response :success
      assert_select "a.bg-gray-900", text: "Users"
      assert_select "p", "No configured users."
    end
  end

  def test_overview_renders_no_clients_waiting_when_pool_pressure_is_zero
    with_stubbed_database_methods(summary: overview_summary(0)) do
      get "/pgbouncerhero/operations/primary/summary"

      assert_response :success
      assert_select "span", text: "No clients waiting", count: 1
    end
  end

  def test_overview_pluralizes_one_waiting_client
    with_stubbed_database_methods(summary: overview_summary(1)) do
      get "/pgbouncerhero/operations/primary/summary"

      assert_response :success
      assert_select "span", text: "1 waiting client", count: 1
    end
  end

  def test_overview_pluralizes_multiple_waiting_clients
    with_stubbed_database_methods(summary: overview_summary(2)) do
      get "/pgbouncerhero/operations/primary/summary"

      assert_response :success
      assert_select "span", text: "2 waiting clients", count: 1
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

  def with_stubbed_database(method, result)
    with_stubbed_database_methods(method => result) { yield }
  end

  def with_stubbed_database_methods(results)
    with_config(<<~YAML) do
      pgbouncers:
        Operations:
          Primary:
            url: postgres://user:pass@localhost:6432/pgbouncer
    YAML
      database = PgBouncerHero.groups.fetch("operations").databases.first
      database.define_singleton_method(:connection) { true }
      results.each do |method, result|
        database.define_singleton_method(method) { result }
      end
      yield
    ensure
      database&.singleton_class&.remove_method(:connection)
      results&.each_key { |method| database.singleton_class.remove_method(method) }
    end
  end

  def overview_summary(waiting_clients)
    [
      { "list" => "users", "items" => "1" },
      { "list" => "databases", "items" => "2" },
      { "list" => "pools", "items" => "1" },
      { databases_details: [ { "name" => "app", "current_connections" => "0", "max_connections" => "10" } ] },
      { pools_details: [ { "cl_waiting" => waiting_clients.to_s } ] }
    ]
  end
end
