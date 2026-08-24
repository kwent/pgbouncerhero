# PgBouncerHero

[![Gem Version](https://badge.fury.io/rb/pgbouncerhero.svg)](https://badge.fury.io/rb/pgbouncerhero)
[![CI](https://github.com/kwent/pgbouncerhero/actions/workflows/test.yml/badge.svg)](https://github.com/kwent/pgbouncerhero/actions/workflows/test.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-ruby.svg)](https://www.ruby-lang.org)

A graphical user interface for your PgBouncers.

[![Screenshot1](https://github.com/kwent/pgbouncerhero/blob/master/doc/screenshot-1.png?raw=true)](https://github.com/kwent/pgbouncerhero)
[![Screenshot2](https://github.com/kwent/pgbouncerhero/blob/master/doc/screenshot-2.png?raw=true)](https://github.com/kwent/pgbouncerhero)
[![Screenshot3](https://github.com/kwent/pgbouncerhero/blob/master/doc/screenshot-3.png?raw=true)](https://github.com/kwent/pgbouncerhero)

## Requirements

- Ruby >= 3.2
- Rails >= 7.2
- Propshaft (asset pipeline)
- importmap-rails

## Installation

Add to your application's Gemfile:

```ruby
gem "pgbouncerhero"
```

And mount the engine in your `config/routes.rb`:

```ruby
mount PgBouncerHero::Engine, at: "pgbouncerhero"
```

### Basic Authentication

Set the following variables in your environment or an initializer.

```ruby
ENV["PGBOUNCERHERO_USERNAME"] = "zelda"
ENV["PGBOUNCERHERO_PASSWORD"] = "triforce"
```

### Devise

```ruby
authenticate :user, ->(user) { user.admin? } do
  mount PgBouncerHero::Engine, at: "pgbouncerhero"
end
```

## One PgBouncer

```bash
export PGBOUNCERHERO_DATABASE_URL=postgres://user:password@host:port/pgbouncer
```

## Multiple PgBouncers

Generate a config file:

```bash
rails generate pgbouncerhero:config
```

Or create `config/pgbouncerhero.yml` manually:

```yml
pgbouncers:
  production:
    primary:
      url: <%= ENV["PGBOUNCER_PRODUCTION_PRIMARY_DATABASE_URL"] %>
    replica:
      url: <%= ENV["PGBOUNCER_PRODUCTION_REPLICA_DATABASE_URL"] %>
  staging:
    primary:
      url: <%= ENV["PGBOUNCER_STAGING_PRIMARY_DATABASE_URL"] %>
    replica:
      url: <%= ENV["PGBOUNCER_STAGING_REPLICA_DATABASE_URL"] %>
```

Environment-specific top-level keys are also supported. PgBouncerHero reads
`config/pgbouncerhero.yml` from the host application's `Rails.root` by default.
An initializer can point to a different file:

```ruby
PgBouncerHero.config_path = Rails.root.join("config/pgbouncerhero.production.yml")
```

Changing `PgBouncerHero.env` or `config_path` resets cached groups and closes
their open connections. Call `PgBouncerHero.reset!` after changing a config
file at runtime, or `PgBouncerHero.disconnect!` when only the connections need
to be closed. Stale connections reconnect automatically.

The PostgreSQL connection timeout defaults to five seconds and can be changed
with `PGBOUNCERHERO_TIMEOUT`.

## Development

Start PostgreSQL and PgBouncer with Docker:

```bash
docker compose up --detach --wait
```

Run the dummy Rails app:

```bash
PGBOUNCERHERO_DATABASE_URL=postgres://pgbouncer:pgbouncer@localhost:6432/pgbouncer \
  bundle exec rackup test/dummy/config.ru -p 3000
```

Then open http://localhost:3000/pgbouncerhero.

Run the test suite:

```bash
bundle exec rake                 # unit/integration-free tests + rubocop + herb
bundle exec appraisal rake test  # tests across Rails 7.2, 8.0, and 8.1
bundle exec rake build           # build and validate the gem package
bundle exec rake test:integration # real PgBouncer admin-console tests
```

The integration task expects PostgreSQL and PgBouncer from the Compose stack.
Override `PGBOUNCERHERO_INTEGRATION_URL` to test another PgBouncer instance.
The default is `postgres://pgbouncer:pgbouncer@127.0.0.1:6432/pgbouncer`.

Stop Docker when done:

```bash
docker compose down --volumes
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Add some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Authors

- [Quentin Rousseau](https://github.com/kwent)

## License

Copyright (c) 2025 Quentin Rousseau

MIT License. See [LICENSE.txt](LICENSE.txt) for details.
