module PgBouncerHero
  class Database
    include Methods::Basics

    attr_reader :id, :config, :group

    def initialize(group, id, config)
      @id = id
      @config = config || {}
      @url = URI.parse(config["url"].to_s)
      @group = group
    end

    def name
      @name ||= id.to_s
    end

    def connection
      disconnect! if @connection && connection_invalid?(@connection)
      @connection ||= connection_model.new(host, port, user, password, dbname).connection
    end

    def disconnect!
      @connection&.finish unless @connection&.finished?
    rescue PG::Error
      nil
    ensure
      @connection = nil
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

    def connection_invalid?(connection)
      connection.finished? || connection.status != PG::CONNECTION_OK
    rescue PG::Error
      true
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
  end
end
