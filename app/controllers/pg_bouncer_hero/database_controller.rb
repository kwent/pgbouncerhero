require_dependency 'pg_bouncer_hero/application_controller'

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
      if @database.connection
        @database.reload
        flash[:success] = "#{@database.name} has been reloaded."
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end
    def suspend
      if @database.connection
        @database.suspend
        flash[:success] = "#{@database.name} has been suspended."
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end
    def shutdown
      if @database.connection
        @database.shutdown
        flash[:success] = "#{@database.name} has been shutdown."
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end
  end
end
