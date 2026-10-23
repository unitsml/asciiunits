# frozen_string_literal: true

# corpora/unitsml/inputs.txt -> corpora/unitsml/expected-kinds.json
#
# Freezes the accept/reject behavior of the unitsml gem's Parslet parser as
# the sole oracle. Raises on any disagreement with the declared kinds.

require "json"
require "bundler/setup"
require "unitsml"

ROOT = File.expand_path("..", __dir__)
INPUTS = File.join(ROOT, "corpora/unitsml/inputs.txt")
OUT = File.join(ROOT, "corpora/unitsml/expected-kinds.json")

spec = Gem.loaded_specs.fetch("unitsml")
cases = []
disagreements = []

File.readlines(INPUTS, chomp: true).each do |line|
  next if line.empty? || line.start_with?("#")

  declared, expr = line.split("\t", 2)
  observed =
    begin
      Unitsml.parse(expr)
      "accept"
    rescue StandardError
      "reject"
    end
  if observed != declared.downcase
    disagreements << "#{expr.inspect}: declared #{declared}, parslet says #{observed}"
    next
  end
  cases << { "input" => expr, "kind" => observed }
end

abort "oracle disagrees with inputs.txt declarations — fix inputs.txt:\n#{disagreements.join("\n")}" unless disagreements.empty?

File.write(OUT, JSON.pretty_generate(
  "format" => "asciiunits-oracle/v1",
  "source" => "unitsml #{spec.version}",
  "cases" => cases
) + "\n")
puts "wrote corpora/unitsml/expected-kinds.json (#{cases.size} cases)"
