module PgBouncerHero
  class Connection

    def initialize(host, port, user, password, dbname)
      @host = host
      @port = port
      @user = user
      @password = password
      @dbname = dbname
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
            connect_timeout: ENV["PGBOUNCERHERO_TIMEOUT"] || 5
          )
        rescue => e
          Rails.logger.info("[PGBouncerHero] #{@host}/#{@dbname}: #{e}")
          nil
        end
      end
    end

  end
end
