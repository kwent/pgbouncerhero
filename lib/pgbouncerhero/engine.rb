module PgBouncerHero
  class Engine < ::Rails::Engine
    isolate_namespace PgBouncerHero

    initializer "pgbouncerhero", group: :all do |app|
      if defined?(Sprockets) && Sprockets::VERSION >= "4"
        app.config.assets.precompile << "pgbouncerhero/application.js"
        app.config.assets.precompile << "pgbouncerhero/application.css"
        app.config.assets.precompile << "pgbouncerhero/short-paragraph.png"
      else
        # use a proc instead of a string
        app.config.assets.precompile << proc { |path| path == "pgbouncerhero/application.js" }
        app.config.assets.precompile << proc { |path| path == "pgbouncerhero/application.css" }
        app.config.assets.precompile << proc { |path| path == "pgbouncerhero/short-paragraph.png" }
      end

      PgBouncerHero.time_zone = PgBouncerHero.config["time_zone"] if PgBouncerHero.config["time_zone"]
    end
  end
end
