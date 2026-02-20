require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new

namespace :tailwindcss do
  desc "Build Tailwind CSS"
  task :build do
    sh "bundle exec tailwindcss -i app/assets/stylesheets/pgbouncerhero/application.css -o app/assets/builds/pgbouncerhero/application.css --minify"
  end
end

namespace :herb do
  desc "Lint ERB templates with Herb"
  task :lint do
    sh "bundle exec herb analyze app/views"
  end
end

task default: [ :test, :rubocop, "herb:lint" ]
