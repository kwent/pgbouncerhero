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
        execute("RELOAD")
      end
      def suspend
        execute("SUSPEND")
      end
      def pause(database_name)
        execute_database_command("PAUSE", database_name)
      end
      def reconnect(database_name)
        execute_database_command("RECONNECT", database_name)
      end
      def wait_close(database_name)
        execute_database_command("WAIT_CLOSE", database_name)
      end
      def resume(database_name = nil)
        return execute("RESUME") if database_name.nil?

        execute_database_command("RESUME", database_name)
      end
      def shutdown(mode = nil)
        suffix = SHUTDOWN_MODES.fetch(mode)
        execute("SHUTDOWN#{suffix}")
      rescue KeyError
        raise ArgumentError, "unsupported shutdown mode: #{mode.inspect}"
      end

      private

      def execute_database_command(command, database_name)
        name = database_name.to_s
        raise ArgumentError, "database name must not be empty" if name.empty?

        execute("#{command} #{PG::Connection.quote_ident(name)}")
      end
    end
  end
end
