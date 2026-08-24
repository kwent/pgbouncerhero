require "erb"
require "monitor"
require "pathname"
require "yaml"
require "rails"
require "pg"
require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"

require "pgbouncerhero/version"
require "pgbouncerhero/methods/basics"
require "pgbouncerhero/connection"
require "pgbouncerhero/group"
require "pgbouncerhero/engine"

module PgBouncerHero
  class ConfigurationError < StandardError; end

  BOOLEAN_SETTINGS = {
    true => true,
    false => false,
    "1" => true,
    "0" => false,
    "true" => true,
    "false" => false,
    "yes" => true,
    "no" => false,
    "on" => true,
    "off" => false
  }.freeze
  private_constant :BOOLEAN_SETTINGS

  STATE_MONITOR = Monitor.new
  private_constant :STATE_MONITOR

  mattr_accessor :importmap, default: Importmap::Map.new

  class << self
    attr_reader :env

    def time_zone=(time_zone)
      @time_zone = time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone.to_s]
    end

    def time_zone
      @time_zone || Time.zone
    end

    def env=(env)
      STATE_MONITOR.synchronize do
        @env = env.to_s
        reset!
      end
    end

    def config_path
      STATE_MONITOR.synchronize { @config_path || default_config_path }
    end

    def config_path=(path)
      STATE_MONITOR.synchronize do
        @config_path = path && Pathname(path)
        reset!
      end
    end

    def config
      STATE_MONITOR.synchronize { @config ||= selected_config(load_config) }
    end

    def groups
      STATE_MONITOR.synchronize do
        @groups ||= config.fetch("pgbouncers").to_h do |group_id, _databases|
          [ group_id.parameterize, PgBouncerHero::Group.new(group_id, config.fetch("pgbouncers")) ]
        end
      end
    end

    def read_only?
      value = ENV.fetch("PGBOUNCERHERO_READ_ONLY") { config.fetch("read_only", false) }
      BOOLEAN_SETTINGS.fetch(value.is_a?(String) ? value.downcase : value)
    rescue KeyError
      raise ConfigurationError, "read_only must be a boolean"
    end

    def disconnect!
      STATE_MONITOR.synchronize do
        @groups&.each_value do |group|
          group.databases.each(&:disconnect!)
        end
      end
    end

    def reset!
      STATE_MONITOR.synchronize do
        disconnect!
        @config = nil
        @groups = nil
      end
    end

    private

    def default_config_path
      (Rails.root || Pathname.pwd).join("config/pgbouncerhero.yml")
    end

    def load_config
      return {} unless config_path.file?

      loaded = YAML.safe_load(ERB.new(config_path.read).result, aliases: true)
      return {} if loaded.nil?
      return loaded if loaded.is_a?(Hash)

      raise ConfigurationError, "#{config_path} must contain a YAML mapping"
    end

    def selected_config(loaded)
      selected = loaded.fetch(env, loaded)
      unless selected.is_a?(Hash)
        raise ConfigurationError, "configuration for #{env.inspect} must be a YAML mapping"
      end

      return default_config unless selected.key?("pgbouncers")

      pgbouncers = selected["pgbouncers"]
      unless pgbouncers.is_a?(Hash) && pgbouncers.any? && pgbouncers.values.all? { |databases| databases.is_a?(Hash) && databases.any? }
        raise ConfigurationError, '"pgbouncers" must contain at least one group with one database'
      end

      selected
    end

    def default_config
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

  self.env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
end

at_exit { PgBouncerHero.disconnect! }
