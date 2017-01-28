require "rails/generators"

module PgBouncerHero
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_initializer
        template "config.yml", "config/pgbouncerhero.yml"
      end
    end
  end
end
