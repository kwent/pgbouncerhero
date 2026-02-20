require_relative "lib/pgbouncerhero/version"

Gem::Specification.new do |spec|
  spec.name          = "pgbouncerhero"
  spec.version       = PgBouncerHero::VERSION
  spec.authors       = [ "Quentin Rousseau" ]
  spec.email         = [ "contact@quent.in" ]
  spec.summary       = "A graphical user interface for your PgBouncers"
  spec.description   = "A Rails engine providing a web dashboard for monitoring and managing one or multiple PgBouncer connection poolers."
  spec.homepage      = "https://github.com/kwent/pgbouncerhero"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.files         = Dir["lib/**/*", "app/**/*", "config/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = [ "lib" ]

  spec.metadata = {
    "source_code_uri" => "https://github.com/kwent/pgbouncerhero",
    "changelog_uri" => "https://github.com/kwent/pgbouncerhero/blob/master/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/kwent/pgbouncerhero/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.add_dependency "railties", ">= 7.2"
  spec.add_dependency "importmap-rails", ">= 1.2"
  spec.add_dependency "turbo-rails", ">= 1.0"
  spec.add_dependency "stimulus-rails", ">= 1.0"
  spec.add_dependency "pg", ">= 1.2"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "tailwindcss-rails", "~> 4.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "appraisal", "~> 2.5"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "rubocop-rails-omakase", "~> 1.0"
  spec.add_development_dependency "herb", "~> 0.8"
end
