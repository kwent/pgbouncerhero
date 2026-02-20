require "pgbouncerhero/version"

require "pgbouncerhero/methods/basics"

require "pgbouncerhero/group"
require "pgbouncerhero/engine" if defined?(Rails)

require "pgbouncerhero/connection"

require "pg"
require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"

module PgBouncerHero
  mattr_accessor :importmap, default: Importmap::Map.new

  class << self
    attr_accessor :env
  end
  self.env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"

  class << self
    def time_zone=(time_zone)
      @time_zone = time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone.to_s]
    end

    def time_zone
      @time_zone || Time.zone
    end

    def config
      @config ||= begin
        path = "config/pgbouncerhero.yml"

        config = YAML.safe_load(ERB.new(File.read(path)).result, aliases: true) if File.exist?(path)
        config ||= {}

        if config[env]
          config[env]
        elsif config["pgbouncers"]
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
        mapped = config["pgbouncers"].map do |group_id, _hash|
          [ group_id.parameterize, PgBouncerHero::Group.new(group_id, config["pgbouncers"]) ]
        end
        Hash[mapped]
      end
    end
  end
end
