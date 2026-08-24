module PgBouncerHero
  class DatabaseController < ApplicationController
    DATABASE_ADMIN_ACTIONS = %i[pause_database reconnect_database wait_close_database resume_database].freeze

    before_action :ensure_writable!, only: [ :reload, :suspend, :resume, :shutdown, *DATABASE_ADMIN_ACTIONS ]
    before_action :set_target_database, only: DATABASE_ADMIN_ACTIONS

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

    def servers
      if @database.connection
        @servers = @database.servers
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    end

    def users
      if @database.connection
        @users = @database.users
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

    def state
      if @database.connection
        @state = @database.state
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

    def resume
      execute_admin_command(:resume, "resumed")
    end

    def pause_database
      execute_database_admin_command(:pause, "paused")
    end

    def reconnect_database
      execute_database_admin_command(:reconnect, "asked to reconnect released server connections")
    end

    def wait_close_database
      execute_database_admin_command(:wait_close, "confirmed all marked server connections closed")
    end

    def resume_database
      execute_database_admin_command(:resume, "resumed")
    end

    def shutdown
      execute_admin_command(:shutdown, "asked to shut down after its clients disconnect", :wait_for_clients)
    end

    private

    def ensure_writable!
      return unless PgBouncerHero.read_only?

      render plain: "PgBouncerHero is configured as read-only.", status: :forbidden
    end

    def set_target_database
      @target_database = params[:target_database].to_s
      return if @target_database.present?

      render plain: "A target database is required.", status: :bad_request
    end

    def execute_admin_command(command, past_tense, *arguments)
      if @database.connection
        @database.public_send(command, *arguments)
        flash[:success] = "#{@database.name} has been #{past_tense}."
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    rescue PG::Error => e
      flash[:error] = "#{@database.name}: #{e.message.strip}"
    ensure
      redirect_back fallback_location: root_path
    end

    def execute_database_admin_command(command, past_tense)
      if @database.connection
        @database.public_send(command, @target_database)
        flash[:success] = "#{@target_database} on #{@database.name} has been #{past_tense}."
      else
        flash[:error] = "#{@database.name} does not look online."
      end
    rescue PG::Error => e
      flash[:error] = "#{@database.name}: #{e.message.strip}"
    ensure
      redirect_back fallback_location: databases_path
    end
  end
end
