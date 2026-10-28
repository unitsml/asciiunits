# frozen_string_literal: true

require_relative "lib/asciiunits/version"

Gem::Specification.new do |spec|
  spec.name = "asciiunits"
  spec.version = Asciiunits::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "PARG grammar, artifact and corpus for UnitsML AsciiUnits expressions"
  spec.description = "Checksummed parsanol PARG artifact, terminal tables and " \
                     "oracle-frozen conformance corpus for the unitsml(...) " \
                     "expression syntax of UnitsML. Runtime-agnostic: load the " \
                     "artifact with any Parsanol runtime (Ruby, Rust, wasm)."
  spec.homepage = "https://github.com/unitsml/asciiunits"
  spec.license = "BSD-2-Clause"

  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob(
    "{lib,grammars,tables,artifacts,suites}/**/*",
    base: File.expand_path(__dir__),
  ) + Dir.glob("corpora/unitsml/*", base: File.expand_path(__dir__)) +
    %w[README.adoc LICENSE.md]

  spec.require_paths = ["lib"]

  # The upper cap guarded the v1 tree shapes (1.3.109's emission-level
  # changes); the edition-2 artifact removes the need — the artifact
  # declares its edition and any runtime that cannot read it fails
  # loudly at load. Tighten the floor to the release carrying
  # parsanol-ruby#361 once its number is cut.
  spec.add_dependency "parsanol", ">= 1.3.108"
end
