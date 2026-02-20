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
