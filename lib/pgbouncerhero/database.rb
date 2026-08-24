require "connection_pool"
require "monitor"

module PgBouncerHero
  class Database
    include Methods::Basics

    DEFAULT_POOL_SIZE = 5
    DEFAULT_POOL_TIMEOUT = 5

    attr_reader :id, :config, :group, :pool_size, :pool_timeout

    def initialize(group, id, config)
      @id = id
      @config = config || {}
      @url = URI.parse(@config["url"].to_s)
      @group = group
      @pool_size = positive_integer_setting("pool_size", "PGBOUNCERHERO_POOL_SIZE", DEFAULT_POOL_SIZE)
      @pool_timeout = positive_float_setting("pool_timeout", "PGBOUNCERHERO_POOL_TIMEOUT", DEFAULT_POOL_TIMEOUT)
      @pool_monitor = Monitor.new
    end

    def name
      @name ||= id.to_s
    end

    def connection
      proxy = connection_proxy
      proxy if with_connection { true }
    end

    def with_connection
      pool = connection_pool
      pool.with do |managed_connection|
        managed_connection.with_connection { |raw_connection| yield raw_connection }
      end
    rescue ConnectionPool::TimeoutError => e
      Rails.logger.error("[PGBouncerHero] #{name} connection pool timed out after #{pool_timeout}s: #{e.message}")
      nil
    end

    def disconnect!
      pool = @pool_monitor.synchronize do
        current_pool = @connection_pool
        @connection_pool = nil
        @connection_proxy = nil
        current_pool
      end
      pool&.shutdown(&:disconnect!)
    end

    def host
      @url.host if @url
    end

    def port
      @url.port if @url
    end

    def user
      @url.user if @url
    end

    def password
      @url.password if @url
    end

    def dbname
      @url.path[1..-1] if @url
    end

    private

    def execute(command)
      with_connection { |raw_connection| raw_connection.exec(command) }
    end

    def connection_pool
      @pool_monitor.synchronize do
        @connection_pool ||= ConnectionPool.new(size: pool_size, timeout: pool_timeout) { build_connection }
      end
    end

    def connection_proxy
      @pool_monitor.synchronize do
        @connection_proxy ||= ConnectionPool::Wrapper.new(pool: connection_pool)
      end
    end

    def build_connection
      connection_model.new(host, port, user, password, dbname)
    end

    def connection_model
      @connection_model ||= begin
        Class.new(PgBouncerHero::Connection) do
          def self.name
            "PgBouncerHero::Connection::Database#{object_id}"
          end
        end
      end
    end

    def positive_integer_setting(config_key, environment_key, default)
      value = config.fetch(config_key, ENV.fetch(environment_key, default))
      parsed = Integer(value)
      raise ArgumentError, "#{config_key} must be greater than zero" unless parsed.positive?

      parsed
    end

    def positive_float_setting(config_key, environment_key, default)
      value = config.fetch(config_key, ENV.fetch(environment_key, default))
      parsed = Float(value)
      raise ArgumentError, "#{config_key} must be a finite number greater than zero" unless parsed.positive? && parsed.finite?

      parsed
    end
  end
end
