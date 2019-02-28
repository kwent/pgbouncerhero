# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pgbouncerhero/version"

Gem::Specification.new do |spec|
  spec.name          = "pgbouncerhero"
  spec.version       = PgBouncerHero::VERSION
  spec.authors       = ["Quentin Rousseau"]
  spec.email         = ["contact@quent.in"]
  spec.summary       = "A graphical user interface for your PGBouncers"
  spec.description   = "A graphical user interface for your PGBouncers"
  spec.homepage      = "https://github.com/kwent/pgbouncerhero"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_runtime_dependency "sass-rails"
  spec.add_runtime_dependency "semantic-ui-sass"

  if RUBY_PLATFORM == "java"
    spec.add_runtime_dependency "pg_jruby"
  else
    spec.add_runtime_dependency "pg"
  end
end
