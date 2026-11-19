# frozen_string_literal: true

# Exports the AsciiUnits model's LML declarations and verifies them.
#
# Usage:
#   bundle exec ruby scripts/verify_lml.rb           verify (CI)
#   bundle exec ruby scripts/verify_lml.rb --write   rewrite model/
#
# Every class of Asciiunits::Model (the generated node classes and
# Document) is exported with Lutaml::Model::Lml.export. model/asciiunits.lml.json holds
# the documents, ordered by model name; model/asciiunits.lml.checksums.txt
# holds each document's LML checksum and the file's sha256.
#
# Verification: the committed files equal a fresh export byte for byte,
# every committed document passes Lutaml::Model::Lml.verify (it re-derives
# its model) and the checksums match. Lml.verify re-exports the loaded Ruby
# class; it is not an independent importer. Exits nonzero on the first
# failure.

require "digest"
require "json"
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "asciiunits"
require "asciiunits/model"

ROOT = File.expand_path("..", __dir__)
DOCUMENTS = File.join(ROOT, "model/asciiunits.lml.json")
CHECKSUMS = File.join(ROOT, "model/asciiunits.lml.checksums.txt")
FORMAT = "asciiunits-lml/1"

write = ARGV.delete("--write")
abort "usage: ruby scripts/verify_lml.rb [--write]" unless ARGV.empty?

def model_classes
  Asciiunits::Model.constants.sort.map { |c| Asciiunits::Model.const_get(c) }
                    .select { |k| k.is_a?(Class) && k < Lutaml::Model::Serializable }
end

def export
  documents = model_classes.map { |k| Lutaml::Model::Lml.export(k) }.sort_by(&:model_name)
  json = JSON.pretty_generate(
    "format" => FORMAT,
    "root" => Asciiunits::Model::Document.name,
    "models" => documents.map(&:to_h),
  )
  ["#{json}\n", documents]
end

def checksums(json, documents)
  lines = ["# Written by scripts/verify_lml.rb: the LML checksum of every model",
           "# document, then the sha256 of the documents file.",
           *documents.map { |d| "#{d.model_name} #{d.checksum}" },
           "model/asciiunits.lml.json sha256:#{Digest::SHA256.hexdigest(json)}"]
  "#{lines.join("\n")}\n"
end

json, documents = export
sums = checksums(json, documents)

if write
  Dir.mkdir(File.dirname(DOCUMENTS)) unless Dir.exist?(File.dirname(DOCUMENTS))
  File.binwrite(DOCUMENTS, json)
  File.binwrite(CHECKSUMS, sums)
  puts "wrote #{documents.size} model documents, sha256:#{Digest::SHA256.hexdigest(json)}"
  exit
end

abort "FAILED: #{DOCUMENTS} is missing" unless File.file?(DOCUMENTS)
abort "FAILED: #{DOCUMENTS} differs from a fresh export (run with --write)" unless File.binread(DOCUMENTS) == json
abort "FAILED: #{CHECKSUMS} differs from the export's checksums" unless File.binread(CHECKSUMS) == sums

committed = JSON.parse(File.read(DOCUMENTS, encoding: "UTF-8"))
abort "FAILED: format #{committed['format'].inspect}" unless committed["format"] == FORMAT
committed.fetch("models").each do |hash|
  document = Lutaml::Model::Lml::Document.from_hash(hash)
  Lutaml::Model::Lml.verify(document)
  recorded = sums.lines.find { |l| l.start_with?("#{document.model_name} ") }&.split&.last
  abort "FAILED: #{document.model_name} checksum #{document.checksum} is not the recorded #{recorded}" unless recorded == document.checksum
rescue Lutaml::Model::Lml::RejectedError => e
  abort "FAILED: #{hash['model']}: #{e.message}"
end
puts "verified #{committed['models'].size} model documents, sha256:#{Digest::SHA256.hexdigest(json)}"
