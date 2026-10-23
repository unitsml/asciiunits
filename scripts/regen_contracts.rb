# frozen_string_literal: true

# artifact + inputs.txt + expected-kinds.json -> corpora/unitsml/corpus.json
#
# Runs the artifact over every corpus input, records the parsanol tree, and
# enforces kind parity with the frozen parslet oracle. The artifact never
# defines expected behavior — the oracle does.

require "json"
require "bundler/setup"
require "parsanol"

ROOT = File.expand_path("..", __dir__)
ARTIFACT = File.join(ROOT, "artifacts/unitsml.json")
ORACLE = JSON.parse(File.read(File.join(ROOT, "corpora/unitsml/expected-kinds.json")))
INPUTS = File.readlines(File.join(ROOT, "corpora/unitsml/inputs.txt"), chomp: true)
               .reject { |l| l.empty? || l.start_with?("#") }
OUT = File.join(ROOT, "corpora/unitsml/corpus.json")

expected = ORACLE["cases"].to_h { |c| [c["input"], c["kind"]] }

artifact = Parsanol::PARG::Artifact.load(ARTIFACT, tables_dir: File.join(ROOT, "tables"))

failures = []
cases = INPUTS.filter_map do |line|
  _declared, input = line.split("\t", 2)
  result =
    begin
      tree = artifact.parse("expression", input)
      { "kind" => "accept", "tree" => tree }
    rescue StandardError
      { "kind" => "reject" }
    end
  oracle_kind = expected[input]
  if oracle_kind.nil?
    failures << "#{input.inspect}: not in oracle (inputs.txt/oracle out of sync — run rake oracle:regen)"
    next nil
  end
  if result["kind"] != oracle_kind
    failures << "#{input.inspect}: oracle=#{oracle_kind} artifact=#{result['kind']}"
    next nil
  end
  { "input" => input, "kind" => result["kind"], "parsanol_tree" => result["tree"] }.compact
end

abort "parity failures (#{failures.size}):\n#{failures.join("\n")}" unless failures.empty?

File.write(OUT, JSON.pretty_generate(
  "grammar" => "unitsml",
  "artifact_checksum" => JSON.parse(File.binread(ARTIFACT)).fetch("checksum"),
  "cases" => cases
) + "\n")
puts "corpus: #{cases.size} cases, parity green"
