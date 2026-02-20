module PgBouncerHero
  class Engine < ::Rails::Engine
    isolate_namespace PgBouncerHero

    initializer "pgbouncerhero.assets" do |app|
      app.config.assets.paths << root.join("app/assets/stylesheets")
      app.config.assets.paths << root.join("app/javascript")
    end

    initializer "pgbouncerhero.importmap", before: "importmap" do |app|
      PgBouncerHero.importmap.draw root.join("config/importmap.rb")
      PgBouncerHero.importmap.cache_sweeper watches: root.join("app/javascript")

      ActiveSupport.on_load(:action_controller_base) do
        before_action { PgBouncerHero.importmap.cache_sweeper.execute_if_updated }
      end
    end

    initializer "pgbouncerhero.configuration" do
      PgBouncerHero.time_zone = PgBouncerHero.config["time_zone"] if PgBouncerHero.config["time_zone"]
    end
  end
end
