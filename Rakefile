require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :kkttyl do
  task :build do
    Dir.chdir("ext/kkttyl") do
      `cargo build`
    end
  end

  task :release do
    Dir.chdir("ext/kkttyl") do
      `cargo build --release`
    end
  end
end

task test: "kkttyl:build"
task build: "kkttyl:release"
task default: :test
