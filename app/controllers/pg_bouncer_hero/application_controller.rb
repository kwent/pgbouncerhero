module PgBouncerHero
  class ApplicationController < ActionController::Base
    layout "pg_bouncer_hero/application"

    protect_from_forgery

    http_basic_authenticate_with name: ENV["PGBOUNCERHERO_USERNAME"], password: ENV["PGBOUNCERHERO_PASSWORD"] if ENV["PGBOUNCERHERO_PASSWORD"]

    if respond_to?(:before_action)
      before_action :set_database
    else
      before_filter :set_database
    end

    protected

    def set_database
      @groups = PgBouncerHero.groups
      if params[:group] && params[:database]
        @database = PgBouncerHero.groups[params[:group]].databases.find { |db| db.id.to_s == params[:database].to_s }
      else
        @group = @groups.first
        @database = @groups.first.last.databases.first
      end
    end
  end
end
