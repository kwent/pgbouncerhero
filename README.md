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
- PgBouncer >= 1.23
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
      pool_size: 5
      pool_timeout: 5
      read_only: true
    replica:
      url: <%= ENV["PGBOUNCER_PRODUCTION_REPLICA_DATABASE_URL"] %>
  staging:
    primary:
      url: <%= ENV["PGBOUNCER_STAGING_PRIMARY_DATABASE_URL"] %>
    replica:
      url: <%= ENV["PGBOUNCER_STAGING_REPLICA_DATABASE_URL"] %>

# Optional: allow monitoring while blocking all administrative commands
read_only: true
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

PgBouncerHero keeps a bounded, lazily created connection pool for each
configured PgBouncer. The pool defaults to five connections with a five-second
checkout timeout. Set `PGBOUNCERHERO_POOL_SIZE` and
`PGBOUNCERHERO_POOL_TIMEOUT` to change the defaults for every PgBouncer, or set
`pool_size` and `pool_timeout` on an individual database entry as shown above.
Per-database settings take precedence over environment variables.

Code that needs to issue multiple commands on the same PostgreSQL connection
can lease one explicitly:

```ruby
database.with_connection do |connection|
  connection.exec("SHOW VERSION")
  connection.exec("SHOW CONFIG")
end
```

`database.connection` remains available as a connection-compatible proxy for
existing integrations. Connections are checked when borrowed, and stale or
failed connections are discarded and recreated automatically.

### Safe Administration

The dashboard shows PgBouncer's current state and provides Reload, Suspend,
Resume, and graceful shutdown controls. Dashboard shutdown uses
`SHUTDOWN WAIT_FOR_CLIENTS`: PgBouncer stops accepting new clients and exits
after existing clients disconnect. The Ruby API keeps `database.shutdown` as
the immediate command for compatibility and also accepts `:immediate`,
`:wait_for_clients`, or `:wait_for_servers`. State visibility requires
PgBouncer 1.19 or newer; graceful shutdown modes require PgBouncer 1.23 or
newer.

Set `read_only: true` at the top level of `config/pgbouncerhero.yml`, or set
`PGBOUNCERHERO_READ_ONLY=true`, to hide and server-side reject every
administrative command. The environment variable takes precedence over YAML.
An individual PgBouncer can set `read_only: true` or `false` alongside its URL
to override the top-level YAML default. This allows production instances to be
read-only while staging instances remain writable. The environment variable is
still the highest-precedence global override.

The Databases view provides scoped Pause, Reconnect, Wait close, and Resume
controls for planned maintenance and database failovers. Pause waits for that
database's server connections to be released and makes new client queries wait;
Reconnect replaces released server connections; Wait close confirms marked
connections have drained; and Resume restores client processing. Database names
are quoted before being sent to the PgBouncer admin console.

Monitoring views include Databases, Stats, Pools, Clients, Servers, Users,
Configuration, and State. Overview cards also show a waiting-client indicator
when any pool reports a nonzero `cl_waiting` count. Monitoring pages refresh
automatically every 60 seconds and include a manual Refresh control. Automatic
polling pauses while the browser tab is hidden and refreshes immediately when
the tab becomes visible again. Table views can be searched, sorted by column,
and customized, with each table's visible column choices remembered in local
browser storage and resettable to their defaults. Identifier and maintenance
columns remain visible while wide result sets scroll horizontally.
Administrative controls adapt to the current PgBouncer and database state so
contradictory actions are not shown.

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
CI runs this suite against PgBouncer 1.23, 1.24, and 1.25.

Stop Docker when done:

```bash
docker compose down --volumes
```

### Releasing

Releases use a scoped RubyGems OIDC API Key Role through GitHub Actions, with no
long-lived RubyGems API key. The role is restricted to the `pgbouncerhero` gem,
the `kwent/pgbouncerhero` repository, and the `rubygems.org` audience. Store its
role token in the `RUBYGEMS_OIDC_ROLE` GitHub Actions secret. Then run the
**Release** workflow on `master` and enter the version already committed in
`lib/pgbouncerhero/version.rb`. The workflow verifies the version and test
suite, exchanges GitHub's OIDC identity for a short-lived credential, publishes
the gem, pushes the version tag, and creates the matching GitHub release.

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
