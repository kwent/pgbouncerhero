require "pgbouncerhero/version"

# methods
require "pgbouncerhero/methods/basics"

require "pgbouncerhero/group"
require "pgbouncerhero/engine" if defined?(Rails)

# models
require "pgbouncerhero/connection"

module PgBouncerHero
  # settings
  class << self
    attr_accessor :env
  end
  self.env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"

  class << self
    extend Forwardable

    def time_zone=(time_zone)
      @time_zone = time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone.to_s]
    end

    def time_zone
      @time_zone || Time.zone
    end

    def config
      Thread.current[:PgBouncerHero_config] ||= begin
        path = "config/pgbouncerhero.yml"

        config = YAML.load(ERB.new(File.read(path)).result) if File.exist?(path)
        config ||= {}

        if config[env]
          config[env]
        elsif config["pgbouncers"] # preferred format
          config
        else
          {
            "pgbouncers" => {
              "default" => {
                "primary" => {
                  "url" => ENV["PGBOUNCERHERO_DATABASE_URL"]
                }
              }
            }
          }
        end
      end
    end

    def groups
      @groups ||= begin
        mapped = config['pgbouncers'].map do |group_id, hash|
          [group_id.parameterize, PgBouncerHero::Group.new(group_id, config['pgbouncers'])]
        end
        Hash[mapped]
      end
    end
  end
end
