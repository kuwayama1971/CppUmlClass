# frozen_string_literal: true

require_relative "lib/CppUmlClass/version"

Gem::Specification.new do |spec|
  spec.name = "CppUmlClass"
  spec.version = CppUmlClass::VERSION
  spec.authors = ["Masataka Kuwayama"]
  spec.email = ["masataka.kuwayama@gmail.com"]

  spec.summary = "Create a C++ UML class diagram."
  spec.description = "Create a C++ UML class diagram."
  spec.homepage = "https://github.com/kuwayama1971/CppUmlClass"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

   # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "browser_app_base", "~> 0.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
