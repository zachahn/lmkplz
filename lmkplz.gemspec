lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "lmkplz/version"

Gem::Specification.new do |spec|
  spec.name = "lmkplz"
  spec.version = Lmkplz::VERSION
  spec.authors = ["Zach Ahn"]
  spec.email = ["engineering@zachahn.com"]

  spec.summary = "LMK when a file changes"
  spec.description = "Filesystem watcher"
  spec.license = "MIT"

  spec.files =
    `git ls-files -z`
      .split("\x0")
      .+(Dir.glob("ext/kkttyl/target/release/libkkttyl.*"))
      .reject { |f| f.match(%r{^(bin|test|spec|features)/}) }
      .reject { |f| f == "Rakefile" }
      .reject { |f| File.basename(f)[0] == "." }
      .reject { |f| f.match(%r{\Aext/kkttyl/.*\.d\z}) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ffi", "~> 1.9"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "the_bath_of_zahn"
  spec.add_development_dependency "pry-byebug"
end
