# frozen_string_literal: true

require "bundler/gem_tasks"

require "digest"

desc "Full pipeline: verify tables, oracle, artifact, corpus, run tests"
task ci: %w[tables:check oracle:check artifact:check contracts:check test]

namespace :tables do
  desc "Regenerate terminal tables from the unitsml gem"
  task :gen do
    ruby "scripts/gen_tables.rb"
  end

  desc "Fail if committed tables differ semantically from a fresh generation"
  task :check do
    ruby "scripts/gen_tables.rb --check"
  end
end

namespace :oracle do
  desc "Freeze parslet accept/reject behavior into expected-kinds.json"
  task :regen do
    ruby "scripts/gen_oracle.rb"
  end

  desc "Fail if expected-kinds.json does not match a fresh oracle run"
  task :check do
    before = sha("corpora/unitsml/expected-kinds.json")
    ruby "scripts/gen_oracle.rb"
    abort "oracle stale — run `rake oracle:regen` and commit" unless before == sha("corpora/unitsml/expected-kinds.json")
  end
end

namespace :artifact do
  desc "Compile grammar + tables into the checksummed artifact"
  task :compile do
    ruby "scripts/compile.rb --determinism"
  end

  desc "Fail if the committed artifact differs from a fresh compile"
  task :check do
    require "tmpdir"
    require "json"
    fresh = nil
    Dir.mktmpdir do |dir|
      out = File.join(dir, "unitsml.json")
      sh "bundle exec parsanol parg compile grammars/unitsml.parg -o #{out}"
      fresh = File.binread(out)
    end
    # The engine stamps — the compiling engine's version, its Unicode
    # table source, and the checksum covering both — are provenance,
    # not grammar: the bake's ruby names itself, so a byte comparison
    # fails on every runner whose ruby patch differs (the U3 lesson).
    # The parity view compares everything the grammar determines.
    stamps = %w[compiler_version unicode_tables checksum]
    parity = lambda do |text|
      JSON.parse(text).except(*stamps)
    end
    unless parity.call(File.binread("artifacts/unitsml.json")) == parity.call(fresh)
      abort "artifact stale — run `rake artifact:compile` and commit"
    end
  end
end

namespace :contracts do
  desc "Replay artifact over corpus inputs; record trees; enforce oracle parity"
  task :regen do
    ruby "scripts/regen_contracts.rb"
  end

  desc "Fail if corpus.json does not match a fresh replay"
  task :check do
    before = sha("corpora/unitsml/corpus.json")
    ruby "scripts/regen_contracts.rb"
    abort "corpus stale — run `rake contracts:regen` and commit" unless before == sha("corpora/unitsml/corpus.json")
  end
end

desc "Run the artifact's embedded test block and the pgtest suite"
task :test do
  sh "bundle exec parsanol parg test artifacts/unitsml.json --tables tables"
  sh "bundle exec parsanol parg test artifacts/unitsml.json --tables tables --suite suites"
end

def sha(path)
  Digest::SHA256.file(path).hexdigest
end

require "open3"

task default: :ci
