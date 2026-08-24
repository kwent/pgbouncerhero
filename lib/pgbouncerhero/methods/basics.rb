module PgBouncerHero
  module Methods
    module Basics
      SHUTDOWN_MODES = {
        nil => "",
        immediate: "",
        wait_for_clients: " WAIT_FOR_CLIENTS",
        wait_for_servers: " WAIT_FOR_SERVERS"
      }.freeze

      def summary
        if connection
          l = lists
          d = databases
          p = pools
          l = l.as_json
          d = d.as_json.reject { |a| a["name"] == "pgbouncer" }
          p = p.as_json
          l.push({ databases_details: d })
          l.push({ pools_details: p })
          l
        end
      end
      def databases
        execute("SHOW databases")
      end
      def stats
        execute("SHOW stats")
      end
      def lists
        execute("SHOW lists")
      end
      def pools
        execute("SHOW pools")
      end
      def clients
        execute("SHOW clients")
      end
      def servers
        execute("SHOW servers")
      end
      def users
        execute("SHOW users")
      end
      def conf
        execute("SHOW config")
      end
      def state
        execute("SHOW state")
      end
      def reload
        instrument_admin_command(:reload) { execute("RELOAD") }
      end
      def suspend
        instrument_admin_command(:suspend) { execute("SUSPEND") }
      end
      def pause(database_name)
        execute_database_command(:pause, "PAUSE", database_name)
      end
      def reconnect(database_name)
        execute_database_command(:reconnect, "RECONNECT", database_name)
      end
      def wait_close(database_name)
        execute_database_command(:wait_close, "WAIT_CLOSE", database_name)
      end
      def resume(database_name = nil)
        return instrument_admin_command(:resume) { execute("RESUME") } if database_name.nil?

        execute_database_command(:resume, "RESUME", database_name)
      end
      def shutdown(mode = nil)
        instrument_admin_command(:shutdown, mode: mode || :immediate) do
          suffix = SHUTDOWN_MODES.fetch(mode)
          execute("SHUTDOWN#{suffix}")
        rescue KeyError
          raise ArgumentError, "unsupported shutdown mode: #{mode.inspect}"
        end
      end

      private

      def execute_database_command(action, command, database_name)
        name = database_name.to_s
        instrument_admin_command(action, target_database: name) do
          raise ArgumentError, "database name must not be empty" if name.empty?

          execute("#{command} #{PG::Connection.quote_ident(name)}")
        end
      end

      def instrument_admin_command(action, target_database: nil, **attributes)
        payload = {
          group: group.name,
          database: name,
          action: action,
          target_database: target_database,
          **attributes
        }

        error = nil
        result = ActiveSupport::Notifications.instrument(PgBouncerHero::ADMIN_COMMAND_EVENT, payload) do
          begin
            command_result = yield
            payload[:outcome] = command_result.nil? ? :unavailable : :success
            command_result
          rescue StandardError => command_error
            error = command_error
            payload[:outcome] = :error
            payload[:error_class] = command_error.class.name
            nil
          end
        end
        raise error if error

        result
      end
    end
  end
end
