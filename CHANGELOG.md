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
