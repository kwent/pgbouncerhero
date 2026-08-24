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

  def test_monitoring_pages_render_refreshable_turbo_frames
    results = {
      databases: [ { "name" => "app" } ],
      stats: [ { "database" => "app" } ],
      pools: [ { "database" => "app" } ],
      clients: [ { "database" => "app" } ],
      servers: [ { "database" => "app" } ],
      users: [ { "name" => "app" } ],
      conf: [ { "key" => "pool_mode", "value" => "transaction" } ],
      state: [ { "key" => "active" } ]
    }

    with_stubbed_database_methods(results) do
      results.each_key do |action|
        get "/pgbouncerhero/operations/primary/#{action}"

        assert_response :success
        assert_select "div[data-controller='polling'][data-polling-interval-value='60000']", count: 1
        assert_select "turbo-frame#monitoring_#{action}[data-polling-refresh-url='/pgbouncerhero/operations/primary/#{action}']", count: 1
        assert_select "turbo-frame#monitoring_#{action}[src]", count: 0
        assert_select "button[data-action='polling#refresh']", text: "Refresh", count: 1
        assert_select "span[data-polling-target='status']", text: "Updated just now", count: 1
      end
    end
  end

  def test_overview_renders_no_clients_waiting_when_pool_pressure_is_zero
    with_stubbed_database_methods({ summary: overview_summary(0) }) do
      get "/pgbouncerhero/operations/primary/summary"

      assert_response :success
      assert_select "span", text: "No clients waiting", count: 1
    end
  end

  def test_overview_pluralizes_one_waiting_client
    with_stubbed_database_methods({ summary: overview_summary(1) }) do
      get "/pgbouncerhero/operations/primary/summary"

      assert_response :success
      assert_select "span", text: "1 waiting client", count: 1
    end
  end

  def test_overview_pluralizes_multiple_waiting_clients
    with_stubbed_database_methods({ summary: overview_summary(2) }) do
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

  def test_read_only_mode_hides_and_blocks_database_maintenance_controls
    rows = [ { "name" => "app", "paused" => "0" }, { "name" => "pgbouncer", "paused" => "0" } ]
    with_stubbed_database_methods({ databases: rows }, read_only: true) do
      get "/pgbouncerhero/operations/primary/databases"

      assert_response :success
      assert_select "th", text: "Maintenance", count: 0
      assert_select "form[action$='/pause_database']", count: 0
      authenticity_token = css_select("meta[name='csrf-token']").first["content"]

      post "/pgbouncerhero/operations/primary/pause_database",
        params: { authenticity_token: authenticity_token, target_database: "app" }

      assert_response :forbidden
      assert_equal "PgBouncerHero is configured as read-only.", response.body
    end
  end

  def test_database_page_renders_scoped_maintenance_controls
    rows = [ { "name" => "app", "paused" => "0" }, { "name" => "pgbouncer", "paused" => "0" } ]
    with_stubbed_database_methods({ databases: rows, state: active_state }) do
      get "/pgbouncerhero/operations/primary/databases"

      assert_response :success
      assert_select "th", text: "Maintenance", count: 1
      %w[pause_database reconnect_database wait_close_database].each do |action|
        assert_select "form[action$='/#{action}']", count: 1 do
          assert_select "input[name='target_database'][value='app']", count: 1
        end
      end
      assert_select "form[action$='/resume_database']", count: 0
    end
  end

  def test_database_page_replaces_pause_with_resume_for_a_paused_database
    rows = [ { "name" => "app", "paused" => "1" }, { "name" => "pgbouncer", "paused" => "0" } ]
    with_stubbed_database_methods({ databases: rows, state: active_state }) do
      get "/pgbouncerhero/operations/primary/databases"

      assert_response :success
      assert_select "form[action$='/pause_database']", count: 0
      %w[reconnect_database wait_close_database resume_database].each do |action|
        assert_select "form[action$='/#{action}']", count: 1
      end
    end
  end

  def test_monitoring_tables_render_search_and_column_controls
    rows = [ { "database" => "app", "cl_active" => "1", "cl_waiting" => "0" } ]
    with_stubbed_database_methods({ pools: rows, state: active_state }) do
      get "/pgbouncerhero/operations/primary/pools"

      assert_response :success
      assert_select "div[data-controller='data-table']", count: 1
      assert_select "input[type='search'][data-data-table-target='query']", count: 1
      assert_select "div[data-data-table-target='columnMenu']", count: 1
      assert_select "tr[data-data-table-target='row']", count: 1
      assert_select "th[data-column-key='database']", count: 1
    end
  end

  def test_database_maintenance_requires_a_target_database
    with_stubbed_database_methods({}) do
      get "/pgbouncerhero/operations/primary/state"
      authenticity_token = css_select("meta[name='csrf-token']").first["content"]

      post "/pgbouncerhero/operations/primary/pause_database", params: { authenticity_token: authenticity_token }

      assert_response :bad_request
      assert_equal "A target database is required.", response.body
    end
  end

  def test_database_maintenance_routes_dispatch_scoped_commands
    calls = []
    methods = %i[pause reconnect wait_close resume].to_h do |method|
      [ method, ->(target_database) { calls << [ method, target_database ] } ]
    end
    with_stubbed_database_methods(methods) do
      get "/pgbouncerhero/operations/primary/state"
      authenticity_token = css_select("meta[name='csrf-token']").first["content"]

      %w[pause reconnect wait_close resume].each do |command|
        post "/pgbouncerhero/operations/primary/#{command}_database",
          params: { authenticity_token: authenticity_token, target_database: "app" }

        assert_response :redirect
      end
    end

    assert_equal %i[pause reconnect wait_close resume].map { |method| [ method, "app" ] }, calls
  end

  def test_writable_mode_renders_suspend_while_pgbouncer_is_active
    with_stubbed_database_methods({ state: active_state }) do
      get "/pgbouncerhero/operations/primary/state"

      assert_response :success
      assert_select "form[action$='/reload']", count: 1
      assert_select "form[action$='/suspend']", count: 1
      assert_select "form[action$='/resume']", count: 0
      assert_select "form[action$='/shutdown']", count: 1
      assert_select "button", "Graceful shutdown"
    end
  end

  def test_writable_mode_replaces_suspend_with_resume_while_pgbouncer_is_suspended
    with_stubbed_database_methods({ state: suspended_state }) do
      get "/pgbouncerhero/operations/primary/state"

      assert_response :success
      assert_select "form[action$='/suspend']", count: 0
      assert_select "form[action$='/resume']", count: 1
      assert_select "button", "Resume all"
    end
  end

  private

  def active_state
    [ { "key" => "active", "value" => "yes" }, { "key" => "paused", "value" => "no" }, { "key" => "suspended", "value" => "no" } ]
  end

  def suspended_state
    [ { "key" => "active", "value" => "no" }, { "key" => "paused", "value" => "no" }, { "key" => "suspended", "value" => "yes" } ]
  end

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
    with_stubbed_database_methods({ method => result }) { yield }
  end

  def with_stubbed_database_methods(results, read_only: false)
    with_config(<<~YAML) do
      read_only: #{read_only}
      pgbouncers:
        Operations:
          Primary:
            url: postgres://user:pass@localhost:6432/pgbouncer
    YAML
      database = PgBouncerHero.groups.fetch("operations").databases.first
      database.define_singleton_method(:connection) { true }
      defaulted_state = !results.key?(:state)
      state_result = active_state
      database.define_singleton_method(:state) { state_result } if defaulted_state
      results.each do |method, result|
        database.define_singleton_method(method) { |*arguments| result.respond_to?(:call) ? result.call(*arguments) : result }
      end
      yield
    ensure
      database&.singleton_class&.remove_method(:connection)
      results&.each_key { |method| database.singleton_class.remove_method(method) }
      database&.singleton_class&.remove_method(:state) if defaulted_state
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
