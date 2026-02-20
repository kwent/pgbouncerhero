module PgBouncerHero
  class DatabaseController < ApplicationController
    def summary
      if @database.connection
        @dbs = @database.summary
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end

    def databases
      if @database.connection
        @dbs = @database.databases
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end

    def stats
      if @database.connection
        @stats = @database.stats
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end

    def pools
      if @database.connection
        @pools = @database.pools
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end

    def clients
      if @database.connection
        @clients = @database.clients
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end

    def conf
      if @database.connection
        @conf = @database.conf
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end

    def reload
      execute_admin_command(:reload, "reloaded")
    end

    def suspend
      execute_admin_command(:suspend, "suspended")
    end

    def shutdown
      execute_admin_command(:shutdown, "shut down")
    end

    private

    def execute_admin_command(command, past_tense)
      if @database.connection
        @database.public_send(command)
        flash[:success] = "#{@database.name} has been #{past_tense}."
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    rescue PG::Error => e
      flash[:error] = "#{@database.name}: #{e.message.strip}"
    ensure
      redirect_back fallback_location: root_path
    end
  end
end
