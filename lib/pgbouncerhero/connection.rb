module PgBouncerHero
  class Connection
    def initialize(host, port, user, password, dbname)
      @host = host
      @port = port
      @user = user
      @password = password
      @dbname = dbname
      @timeout = ENV["PGBOUNCERHERO_TIMEOUT"] || 5
    end

    def connection
      disconnect! if @connection && connection_invalid?(@connection)
      @connection ||= connect
    rescue StandardError => e
      Rails.logger.error("[PGBouncerHero] Host:#{@host} | Database Name:#{@dbname} | Timeout: #{@timeout}s => #{e}")
      nil
    end

    def connected?
      !connection.nil?
    end

    def with_connection
      raw_connection = connection
      return unless raw_connection

      yield raw_connection
    rescue PG::Error
      disconnect!
      raise
    end

    def disconnect!
      @connection&.finish unless @connection&.finished?
    rescue PG::Error
      nil
    ensure
      @connection = nil
    end

    def method_missing(method_name, *, **, &)
      with_connection { |raw_connection| raw_connection.public_send(method_name, *, **, &) }
    end

    def respond_to_missing?(method_name, include_private = false)
      PG::Connection.public_instance_methods(include_private).include?(method_name) || super
    end

    private

    def connect
      PG.connect(
        host: @host,
        port: @port,
        user: @user,
        password: @password,
        dbname: @dbname,
        connect_timeout: @timeout
      )
    end

    def connection_invalid?(connection)
      connection.finished? || connection.status != PG::CONNECTION_OK
    rescue PG::Error
      true
    end
  end
end
