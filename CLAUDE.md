# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PgBouncerHero is a Ruby gem that ships as a **Rails Engine** providing a web dashboard for monitoring and managing one or multiple PgBouncer connection poolers. Version 3.0.0, MIT licensed.

## Requirements

- Ruby >= 3.2
- Rails >= 7.2

## Commands

```bash
bundle install                # Install dependencies
bundle exec rake test         # Run minitest suite
bundle exec rubocop           # Run RuboCop linter
bundle exec herb analyze app/views  # Run Herb ERB linter
bundle exec rake              # Run all (test + rubocop + herb:lint)
gem build pgbouncerhero.gemspec  # Build the gem
bundle exec appraisal install    # Install Appraisal gemfiles
bundle exec appraisal rake test  # Run tests across Rails versions
```

## Architecture

**Rails Engine** mounted into a host app via `mount PgBouncerHero::Engine, at: "pgbouncerhero"`. Uses `isolate_namespace PgBouncerHero`.

### Core library (`lib/`)

- `lib/pgbouncerhero.rb` — Entry point. Loads config from `config/pgbouncerhero.yml` (ERB-parsed YAML with `YAML.safe_load`) or `PGBOUNCERHERO_DATABASE_URL` env var. Exposes `.groups` (memoized hash of Group objects) and `.importmap` (Importmap::Map instance). Config is cached at module level (`@config`).
- `lib/pgbouncerhero/engine.rb` — Registers asset paths for Propshaft, sets up importmap, configures time zone.
- `lib/pgbouncerhero/connection.rb` — Wraps `PG.connect` with configurable timeout (default 5s, override via `PGBOUNCERHERO_TIMEOUT`). Returns `nil` on connection failure.
- `lib/pgbouncerhero/database.rb` — Parses a PgBouncer URL, lazily creates a Connection.
- `lib/pgbouncerhero/group.rb` — Collection of Database instances.
- `lib/pgbouncerhero/methods/basics.rb` — Mixin executing PgBouncer admin commands.

### Frontend Stack

- **Propshaft** for asset pipeline (no Sprockets)
- **importmap-rails** for JavaScript delivery (no bundler/webpack)
- **Turbo + Stimulus** (Hotwire) for interactivity
- **Tailwind CSS 4** for styling

### Controllers (`app/controllers/pg_bouncer_hero/`)

- `HomeController` — `index` renders overview of all groups/databases as cards.
- `DatabaseController` — Per-database actions: `summary` (Turbo Frame), `databases`, `stats`, `pools`, `clients`, `conf`, `reload`, `suspend`, `shutdown`.

### JavaScript (`app/javascript/pgbouncerhero/`)

- `application.js` — Imports Turbo, Stimulus, and registers controllers.
- `controllers/polling_controller.js` — Stimulus controller that reloads Turbo Frames every 60s.

### Routing (`config/routes.rb`)

Routes are nested under `/:group/:database/` with constraints validating against configured group/database names. The summary endpoint returns HTML inside a `<turbo-frame>` for lazy-loading.

### Authentication

Optional HTTP Basic Auth via `PGBOUNCERHERO_USERNAME` / `PGBOUNCERHERO_PASSWORD` env vars (only active when password is set). Also supports Devise `authenticate` block mounting.

## Key Conventions

- ERB templates with Tailwind CSS utility classes.
- Turbo Frames for lazy-loading and AJAX-like behavior.
- Stimulus controllers for client-side interactivity.
- `button_to` with `data-turbo-confirm` for destructive actions (reload, suspend, shutdown).
- Graceful degradation: offline PgBouncers show "Offline" status rather than raising exceptions.

## Testing

- `test/dummy/` — Minimal Rails app for integration testing.
- `test/test_helper.rb` — Loads dummy app and minitest.
- Tests cover: version, config, groups, connection, database, helpers.
- Appraisal tests against Rails 7.2, 8.0, and 8.1.
- CI runs Ruby 3.2/3.3/3.4 x Rails 7.2/8.0/8.1.

## Linting

- **RuboCop** with `rubocop-rails-omakase` (Rails team's standard config).
- **Herb** for ERB template linting and formatting.
