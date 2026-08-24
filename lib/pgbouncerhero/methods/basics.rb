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
      def resume
        execute("RESUME")
      end
      def shutdown(mode = nil)
        suffix = SHUTDOWN_MODES.fetch(mode)
        execute("SHUTDOWN#{suffix}")
      rescue KeyError
        raise ArgumentError, "unsupported shutdown mode: #{mode.inspect}"
      end
    end
  end
end
