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
      @connection ||= begin
         begin
          PG.connect(
            host: @host,
            port: @port,
            user: @user,
            password: @password,
            dbname: @dbname,
            connect_timeout: @timeout
          )
        rescue Exception => e
          Rails.logger.error("[PGBouncerHero] Host:#{@host} | Database Name:#{@dbname} | Timeout: #{@timeout}s => #{e}")
          nil
        end
      end
    end

  end
end
