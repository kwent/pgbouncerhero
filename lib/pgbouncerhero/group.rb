require "pgbouncerhero/database"

module PgBouncerHero
  class Group

    attr_reader :id, :config, :databases

    def initialize(id, config)
      @id = id
      @config = config || {}
      @databases = config[id].map do |k, v|
        PgBouncerHero::Database.new(self, k, config[id][k])
      end
    end

    def name
      @name ||= id.to_s
    end

  end
end
