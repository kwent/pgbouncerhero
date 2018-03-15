module PgBouncerHero
  module Methods
    module Basics
      def summary
        if connection
          l = lists
          d = databases
          l = l.as_json
          d = d.as_json.reject { |a| a['name'] == 'pgbouncer' }
          l.push({databases_details: d})
          l
        end
      end
      def databases
        connection.exec("SHOW databases")
      end
      def stats
        connection.exec("SHOW stats")
      end
      def lists
        connection.exec("SHOW lists")
      end
      def pools
        connection.exec("SHOW pools")
      end
      def clients
        connection.exec("SHOW clients")
      end
      def conf
        connection.exec("SHOW config")
      end
      def reload
        connection.exec("RELOAD")
      end
      def suspend
        connection.exec("SUSPEND")
      end
      def shutdown
        connection.exec("SHUTDOWN")
      end
    end
  end
end
