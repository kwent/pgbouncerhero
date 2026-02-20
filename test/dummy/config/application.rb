require_relative "boot"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "propshaft"
require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"

Bundler.require(*Rails.groups)
require "pgbouncerhero"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("../..", __FILE__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = "test-secret-key-base-for-pgbouncerhero"
  end
end
