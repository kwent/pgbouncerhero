# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PgBouncerHero is a Ruby gem that ships as a **Rails Engine** providing a web dashboard for monitoring and managing one or multiple PgBouncer connection poolers. Version 3.2.0, MIT licensed.

## Requirements

- Ruby >= 3.2
- Rails >= 7.2
- PgBouncer >= 1.23

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
bundle exec rake test:integration # Run real PgBouncer tests after docker compose up -d --wait
```

Releases run through `.github/workflows/release.yml` using a scoped RubyGems
OIDC API Key Role stored as the `RUBYGEMS_OIDC_ROLE` GitHub Actions secret. The
workflow is manually dispatched from `master` with the version already
committed in `lib/pgbouncerhero/version.rb`; it verifies the suite, publishes
the gem with a short-lived credential, pushes the tag, and creates the GitHub
release.

## Architecture

**Rails Engine** mounted into a host app via `mount PgBouncerHero::Engine, at: "pgbouncerhero"`. Uses `isolate_namespace PgBouncerHero`.

### Core library (`lib/`)

- `lib/pgbouncerhero.rb` — Entry point. Loads config from the host application's `config/pgbouncerhero.yml` (ERB-parsed YAML with `YAML.safe_load`) or `PGBOUNCERHERO_DATABASE_URL`. Exposes `.groups`, `.config_path`, `.reset!`, and `.importmap`. Config and groups are cached at module level.
- `lib/pgbouncerhero/engine.rb` — Registers asset paths for Propshaft, sets up importmap, configures time zone.
- `lib/pgbouncerhero/connection.rb` — Wraps `PG.connect` with configurable timeout (default 5s, override via `PGBOUNCERHERO_TIMEOUT`), validates connections before reuse, and reconnects after failures.
- `lib/pgbouncerhero/database.rb` — Parses a PgBouncer URL and owns a bounded, lazy connection pool per PgBouncer. Pool size and checkout timeout default to 5 and are configurable globally or per database.
- `lib/pgbouncerhero/group.rb` — Collection of Database instances.
- `lib/pgbouncerhero/methods/basics.rb` — Mixin executing PgBouncer monitoring and process-control commands, including safe shutdown modes.
  Administrative commands emit structured `admin_command.pgbouncerhero` Active Support notifications for host-app auditing.

### Frontend Stack

- **Propshaft** for asset pipeline (no Sprockets)
- **importmap-rails** for JavaScript delivery (no bundler/webpack)
- **Turbo + Stimulus** (Hotwire) for interactivity
- **Tailwind CSS 4** for styling

### Controllers (`app/controllers/pg_bouncer_hero/`)

- `HomeController` — `index` renders overview of all groups/databases as cards.
- `DatabaseController` — Per-database monitoring and administrative actions. Administrative POST actions are blocked when read-only mode is enabled.

### JavaScript (`app/javascript/pgbouncerhero/`)

- `application.js` — Imports Turbo, Stimulus, and registers controllers.
- `controllers/polling_controller.js` — Stimulus controller that reloads Turbo Frames every 60s.

### Routing (`config/routes.rb`)

Routes are nested under `/:group/:database/` with constraints validating against configured group/database names. The summary endpoint returns HTML inside a `<turbo-frame>` for lazy-loading.

### Authentication

Optional HTTP Basic Auth via `PGBOUNCERHERO_USERNAME` / `PGBOUNCERHERO_PASSWORD` env vars (only active when password is set). Also supports Devise `authenticate` block mounting.
Optional read-only mode via top-level or per-PgBouncer `read_only: true` hides and rejects process-control commands. `PGBOUNCERHERO_READ_ONLY` is the highest-precedence global override.

## Key Conventions

- ERB templates with Tailwind CSS utility classes.
- Turbo Frames for lazy-loading and AJAX-like behavior.
- Stimulus controllers for client-side interactivity.
- `button_to` with `data-turbo-confirm` for destructive actions (reload, suspend, shutdown).
- Graceful degradation: offline PgBouncers show "Offline" status rather than raising exceptions.

## Testing

- `test/dummy/` — Minimal Rails app for integration testing.
- `test/test_helper.rb` — Loads dummy app and minitest.
- Unit tests cover: version, configuration loading, groups, pooled connection lifecycle and concurrency, helpers, routing, and engine rendering.
- `test/integration/` exercises real PgBouncer admin queries, summaries, process controls, authentication, reconnection, and concurrent pooled checkouts against PgBouncer 1.23, 1.24, and 1.25 in CI.
- Appraisal tests against Rails 7.2, 8.0, and 8.1.
- CI runs Ruby 3.2/3.3/3.4/4.0 x Rails 7.2/8.0/8.1.

## Linting

- **RuboCop** with `rubocop-rails-omakase` (Rails team's standard config).
- **Herb** for ERB template linting and formatting.
