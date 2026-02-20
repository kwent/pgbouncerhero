# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PgBouncerHero is a Ruby gem that ships as a **Rails Engine** providing a web dashboard for monitoring and managing one or multiple PgBouncer connection poolers. Version 2.0.0, MIT licensed.

## Commands

```bash
bundle install              # Install dependencies
gem build pgbouncerhero.gemspec  # Build the gem
bundle exec rake test       # Run tests (minitest; no test files exist yet)
```

There is no Rakefile, no linter config, and no CI pipeline configured.

## Architecture

**Rails Engine** mounted into a host app via `mount PgBouncerHero::Engine, at: "pgbouncerhero"`. Uses `isolate_namespace PgBouncerHero`.

### Core library (`lib/`)

- `lib/pgbouncerhero.rb` — Entry point. Loads config from `config/pgbouncerhero.yml` (ERB-parsed YAML) or `PGBOUNCERHERO_DATABASE_URL` env var. Exposes `.groups` (memoized hash of Group objects). Config is cached per-thread (`Thread.current`).
- `lib/pgbouncerhero/connection.rb` — Wraps `PG.connect` with configurable timeout (default 5s, override via `PGBOUNCERHERO_TIMEOUT`). Returns `nil` on connection failure.
- `lib/pgbouncerhero/database.rb` — Parses a PgBouncer URL, lazily creates a Connection. Creates a dynamic anonymous subclass of Connection per database for isolation.
- `lib/pgbouncerhero/group.rb` — Collection of Database instances.
- `lib/pgbouncerhero/methods/basics.rb` — Mixin executing PgBouncer admin commands (`SHOW databases/stats/lists/pools/clients/config`, `RELOAD`, `SUSPEND`, `SHUTDOWN`).

### Controllers (`app/controllers/pg_bouncer_hero/`)

- `HomeController` — `index` renders overview of all groups/databases as cards.
- `DatabaseController` — Per-database actions: `summary` (AJAX), `databases`, `stats`, `pools`, `clients`, `conf`, `reload`, `suspend`, `shutdown`.

### Routing (`config/routes.rb`)

Routes are nested under `/:group/:database/` with constraints validating against configured group/database names. The summary endpoint returns JS (`summary.js.erb`) for AJAX lazy-loading.

### Frontend

- **Semantic UI** (via `semantic-ui-sass`) and **jQuery** (via `jquery-rails`).
- Home page cards lazy-load via AJAX `GET /summary` on DOMContentLoaded, refreshing every 60 seconds.
- `summary.js.erb` updates card DOM with jQuery (online/offline status, connection bars).
- The `_actions.html.erb` partial (Pause/Resume/Disable/Enable/Kill buttons) is UI-only with no backend wiring.

### Authentication

Optional HTTP Basic Auth via `PGBOUNCERHERO_USERNAME` / `PGBOUNCERHERO_PASSWORD` env vars (only active when password is set). Also supports Devise `authenticate` block mounting.

## Key Conventions

- ERB templates only (Haml was dropped in v1.0.3).
- Controllers support both `before_action` (Rails 4+) and `before_filter` (older Rails) via `respond_to?` check.
- Engine handles both Sprockets 3 (proc-based) and Sprockets 4 (string-based) asset precompilation.
- Graceful degradation: offline PgBouncers show "Offline" status rather than raising exceptions.
