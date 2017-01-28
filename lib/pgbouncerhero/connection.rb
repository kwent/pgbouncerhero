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
      begin
        PG.connect(
          host: @host,
          port: @port,
          user: @user,
          password: @password,
          dbname: @dbname,
          connect_timeout: 5
        )
      rescue => e
        Rails.logger.info(e)
        nil
      end
    end

  end
end
