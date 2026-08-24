require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"
require "tempfile"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"].exclude("test/integration/**/*")
end

namespace :test do
  Rake::TestTask.new(:integration) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList["test/integration/**/*_test.rb"]
  end
end

RuboCop::RakeTask.new

namespace :tailwindcss do
  input = "app/assets/stylesheets/pgbouncerhero/application.css"
  output = "app/assets/builds/pgbouncerhero/application.css"

  desc "Build Tailwind CSS"
  task :build do
    sh "bundle exec tailwindcss -i #{input} -o #{output} --minify"
  end

  desc "Verify the committed Tailwind CSS build is current"
  task :check do
    Tempfile.create([ "pgbouncerhero-tailwind", ".css" ]) do |file|
      sh "bundle exec tailwindcss -i #{input} -o #{file.path} --minify"
      abort "Tailwind CSS build is stale; run `bundle exec rake tailwindcss:build`." unless FileUtils.compare_file(output, file.path)
    end
  end
end

namespace :herb do
  desc "Lint ERB templates with Herb"
  task :lint do
    sh "bundle exec herb analyze app/views"
  end
end

task default: [ :test, :rubocop, "herb:lint", "tailwindcss:check" ]
