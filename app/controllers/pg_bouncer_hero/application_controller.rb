module PgBouncerHero
  class ApplicationController < ActionController::Base
    layout "pg_bouncer_hero/application"

    protect_from_forgery with: :exception

    http_basic_authenticate_with name: ENV["PGBOUNCERHERO_USERNAME"], password: ENV["PGBOUNCERHERO_PASSWORD"] if ENV["PGBOUNCERHERO_PASSWORD"]

    before_action :set_database

    protected

    def set_database
      @groups = PgBouncerHero.groups
      if params[:group] && params[:database]
        @group = @groups.fetch(params[:group])
        @database = @group.databases.find { |database| database.name.parameterize == params[:database] }
      else
        _group_id, @group = @groups.first
        @database = @group.databases.first
      end
    end
  end
end
