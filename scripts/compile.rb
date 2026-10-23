# frozen_string_literal: true

# grammars/unitsml.parg + tables/ -> artifacts/unitsml.json
#
# Steps: parsanol parg compile, parsanol parg check (artifact matches source
# + compiler), optional --determinism (recompile must be byte-identical),
# then write artifacts/unitsml.checksums.txt. Exits nonzero on first failure.

require "digest"
require "json"
require "open3"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
GRAMMAR = File.join(ROOT, "grammars/unitsml.parg")
ARTIFACT = File.join(ROOT, "artifacts/unitsml.json")
CHECKSUMS = File.join(ROOT, "artifacts/unitsml.checksums.txt")

determinism = ARGV.delete("--determinism")
abort "usage: ruby scripts/compile.rb [--determinism]" unless ARGV.empty?

def run!(*cmd)
  out, status = Open3.capture2e(*cmd, chdir: ROOT)
  puts out
  abort "FAILED (exit #{status.exitstatus}): #{cmd.join(' ')}" unless status.success?
  out
end

run!("bundle", "exec", "parsanol", "parg", "compile", "grammars/unitsml.parg", "-o", "artifacts/unitsml.json")
run!("bundle", "exec", "parsanol", "parg", "check", "--source", "grammars/unitsml.parg", "--artifact", "artifacts/unitsml.json")

if determinism
  require "fileutils"
  Dir.mktmpdir do |dir|
    again = File.join(dir, "unitsml.json")
    run!("bundle", "exec", "parsanol", "parg", "compile", "grammars/unitsml.parg", "-o", again)
    abort "FAILED: recompilation is not byte-identical" unless File.binread(again) == File.binread(ARTIFACT)
    puts "determinism: recompiled artifact is byte-identical"
  end
end

envelope = JSON.parse(File.binread(ARTIFACT))
lines = [
  "# Written by scripts/compile.rb. Envelope checksum is Parsanol's own;",
  "# the sha256 lines are of the files' bytes.",
  "artifact_checksum #{envelope.fetch('checksum')}",
  "compiler_version #{envelope.fetch('compiler_version')}",
  "source_hash sha256:#{envelope.fetch('source_hash')}",
  "artifacts/unitsml.json sha256:#{Digest::SHA256.file(ARTIFACT).hexdigest}",
  "grammars/unitsml.parg sha256:#{Digest::SHA256.file(GRAMMAR).hexdigest}",
  *Dir["#{ROOT}/tables/*.yaml"].sort.map { |f| "tables/#{File.basename(f)} sha256:#{Digest::SHA256.file(f).hexdigest}" },
  "entries #{envelope.fetch('entries').keys.join(' ')}",
]
File.write(CHECKSUMS, "#{lines.join("\n")}\n")
puts File.read(CHECKSUMS)
