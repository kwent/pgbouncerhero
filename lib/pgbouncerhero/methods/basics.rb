module PgBouncerHero
  module Methods
    module Basics
      def summary
        if connection
          l = lists
          d = databases
          l = l.as_json
          d = d.as_json.reject { |a| a["name"] == "pgbouncer" }
          l.push({ databases_details: d })
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
      def conf
        execute("SHOW config")
      end
      def reload
        execute("RELOAD")
      end
      def suspend
        execute("SUSPEND")
      end
      def shutdown
        execute("SHUTDOWN")
      end
    end
  end
end
