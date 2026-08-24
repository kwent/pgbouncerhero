## Unreleased

## 3.1.0 - 2026-08-23

**New:**
- Read-only mode for hiding and server-side blocking PgBouncer administrative commands
- PgBouncer state visibility and Resume controls
- Integration coverage across supported PgBouncer 1.23, 1.24, and 1.25 releases
- Bounded, thread-safe connection pools per PgBouncer with configurable size and checkout timeout
- Explicit `Database#with_connection` leases for running multiple commands on one connection
- Real PgBouncer integration coverage for admin queries, summaries, reloads, authentication, and reconnection
- A dedicated CI integration job backed by the repository's Docker Compose stack
- Configurable `PgBouncerHero.config_path`, resolved from the host application's `Rails.root` by default
- `PgBouncerHero.reset!` for reloading configuration and connections safely
- Request-level engine coverage and gem-package validation in CI

**Improved:**
- Use `SHUTDOWN WAIT_FOR_CLIENTS` for graceful shutdowns initiated from the dashboard
- Reconnect stale or failed pooled connections automatically and close every pool on reset
- Pin PostgreSQL and PgBouncer development images and wait for container health before testing
- Let Dependabot maintain Docker image versions alongside gems and GitHub Actions
- Protect PgBouncer connections from concurrent use while allowing bounded parallel queries
- Resolve parameterized group and database names consistently in routes and controllers
- Load Rails engine dependencies explicitly and declare Propshaft as a runtime dependency
- Cache Appraisal dependencies directly in the Ruby/Rails CI matrix
- Pin GitHub Actions to their current immutable release commits
- Add read-only workflow permissions, cancellation of superseded runs, and job timeouts

## 3.0.0

**Breaking Changes:**
- Requires Ruby >= 3.2 and Rails >= 7.2
- Removed jQuery, Semantic UI, and Sprockets dependencies
- Replaced with Hotwire (Turbo + Stimulus), Tailwind CSS 4, Propshaft, and importmap-rails
- Removed JRuby support
- Host apps must use Propshaft and importmap-rails

**New:**
- Modern Tailwind CSS 4 UI with responsive design
- Turbo Frames for lazy-loading database cards (replaces jQuery AJAX polling)
- Stimulus controller for 60-second auto-refresh
- RuboCop (rubocop-rails-omakase) for Ruby linting
- Herb for ERB template linting
- Minitest test suite with dummy Rails app
- Appraisal for multi-Rails version testing (7.2, 8.0, 8.1)
- GitHub Actions CI (Ruby 3.2/3.3/3.4/4.0 x Rails 7.2/8.0/8.1)
- Gem metadata (source_code_uri, changelog_uri, bug_tracker_uri, rubygems_mfa_required)

**Improved:**
- `rescue Exception` replaced with `rescue StandardError`
- `YAML.load` replaced with `YAML.safe_load`
- Removed deprecated `require_dependency`
- Removed `before_filter` fallback (Rails 3/4 compat)
- Config caching uses module-level `@config` instead of `Thread.current`
- Removed `html_safe` on flash messages
- Updated config template terminology: `master`/`slave` to `primary`/`replica`

## 2.0.0

- Easier setup
  - Automatically require jquery
  - Automatically require semantic-ui-sass
  - Use pgbouncerhero/application stylesheets and javascript

## 1.0.3

- Drop Haml dependency

## 1.0.1

- Explicitly require ApplicationController. Thanks @Tolsto

## 1.0.0

- Lazy connection for index
- Bug fixes

## 0.1.0

- First major release
