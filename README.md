# PgBouncerHero

A graphical user interface for your PGBouncers.

[See it in action](https://pgbouncerhero-demo.herokuapp.com/). [Source Code](https://github.com/kwent/pgbouncerhero-demo).

[![Screenshot1](https://github.com/kwent/pgbouncerhero/blob/master/doc/screenshot-1.png?raw=true)](https://pgbouncerhero-demo.herokuapp.com/)
[![Screenshot2](https://github.com/kwent/pgbouncerhero/blob/master/doc/screenshot-2.png?raw=true)](https://pgbouncerhero-demo.herokuapp.com/)
[![Screenshot2](https://github.com/kwent/pgbouncerhero/blob/master/doc/screenshot-3.png?raw=true)](https://pgbouncerhero-demo.herokuapp.com/)

## Installation

PgBouncerHero is available as a Rails engine.

Add those dependencies to your application’s Gemfile:

```ruby
gem 'pgbouncerhero'
gem 'jquery-rails'
gem 'sass-rails'
gem 'semantic-ui-sass'
gem 'pg'
```

And mount the engine in your `config/routes.rb`:

```ruby
mount PgBouncerHero::Engine, at: "pgbouncerhero"
```

Add the following line in your `application.css`:

```
*= require pgbouncerhero/application
```

Add the following lines in your `application.js`:

```
//= require jquery
//= require jquery_ujs
//= require pgbouncerhero/application
```

### Basic Authentication

Set the following variables in your environment or an initializer.

```ruby
ENV["PGBOUNCERHERO_USERNAME"] = "zelda"
ENV["PGBOUNCERHERO_PASSWORD"] = "triforce"
```

### Devise

```ruby
authenticate :user, -> (user) { user.admin? } do
  mount PgBouncerHero::Engine, at: "pgbouncerhero"
end
```

## One PgBouncer

```bash
export PGBOUNCERHERO_DATABASE_URL=postgres://user:password@host:port/pgbouncer
```

## Multiple PgBouncers

Create `config/pgbouncerhero.yml` with:

```yml
default: &default
  pgbouncers:
    production:
      master:
        url: <%= ENV["PGBOUNCER_PRODUCTION_MASTER_DATABASE_URL"] %>
      slave:
        url: <%= ENV["PGBOUNCER_PRODUCTION_SLAVE_DATABASE_URL"] %>
    staging:
      master:
        url: <%= ENV["PGBOUNCER_STAGING_MASTER_DATABASE_URL"] %>
      slave:
        url: <%= ENV["PGBOUNCER_STAGING_SLAVE_DATABASE_URL"] %>

development:
  <<: *default

production:
  <<: *default
```

# Authors

- [Quentin Rousseau](https://github.com/kwent)

# License

```plain
Copyright (c) 2017 Quentin Rousseau <contact@quent.in>

MIT License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
```
