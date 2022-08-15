# frozen_string_literal: true
require_relative "lib/excavate/version"

Gem::Specification.new do |spec|
  spec.name          = "excavate"
  spec.version       = Excavate::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Extract nested archives with a single command."
  spec.description   = "Extract nested archives with a single command."
  spec.homepage      = "https://github.com/fontist/excavate"
  spec.license       = "BSD-3-Clause"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fontist/excavate"
  spec.metadata["changelog_uri"] = "https://github.com/fontist/excavate"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features|bin)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "arr-pm", "~> 0.0"
  spec.add_runtime_dependency "ffi-libarchive-binary", "~> 0.0"
  spec.add_runtime_dependency "libmspack", "~> 0.1"
  spec.add_runtime_dependency "ruby-ole", "~> 1.0"
  spec.add_runtime_dependency "rubyzip", "~> 2.3"
  spec.add_runtime_dependency "seven-zip", "~> 1.4"
  spec.add_runtime_dependency "thor", "~> 1.0"
end
