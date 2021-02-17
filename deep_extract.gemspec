# frozen_string_literal: true

require_relative "lib/deep_extract/version"

Gem::Specification.new do |spec|
  spec.name          = "deep_extract"
  spec.version       = DeepExtract::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["operations@ribose.com"]

  spec.summary       = "Extract nested archives with a single command."
  spec.description   = "Extract nested archives with a single command."
  spec.homepage      = "https://github.com/fontist/deep_extract"
  spec.license       = "BSD-3-Clause"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fontist/deep_extract"
  spec.metadata["changelog_uri"] = "https://github.com/fontist/deep_extract"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rubyzip", "~> 2.3.0"

  spec.add_development_dependency "rspec", "~> 3.2"
end
