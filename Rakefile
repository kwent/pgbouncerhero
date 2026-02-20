require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new

namespace :herb do
  desc "Lint ERB templates with Herb"
  task :lint do
    sh "bundle exec herb analyze ."
  end
end

task default: [ :test, :rubocop, "herb:lint" ]
