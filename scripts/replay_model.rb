# frozen_string_literal: true

# Replays corpora/unitsml/corpus.json through the typed model.
#
# Usage:
#   bundle exec ruby scripts/replay_model.rb
#
# For every accept case: Asciiunits.parse_model builds a Document whose
# expression, serialized with the model's JSON mappings, equals the
# recorded parsanol_tree; and Expression.from_json of the recorded tree
# serializes back to the same tree. For every reject case: parse_model
# raises. Also checks that every capture of the artifact's static shapes
# (scripts/capture_shapes.rb) is declared with the type of its kind.
# Exits nonzero with every failure listed.

require "json"
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "asciiunits"
require "asciiunits/model"
require_relative "capture_shapes"

M = Asciiunits::Model

def plain(value)
  case value
  when Hash then value.to_h { |k, v| [k.to_s, plain(v)] }.sort.to_h
  when Array then value.map { |v| plain(v) }
  else value
  end
end

failures = []

shapes = CaptureShapes.new(Asciiunits::ARTIFACT_PATH)
declared = M.classes.each_with_object(Hash.new { |h, k| h[k] = [] }) do |klass, acc|
  next if [M::Document, M::Slice].include?(klass)

  klass.attributes.each { |name, attr| acc[name.to_s] << attr.type }
end
shapes.captures.each do |name, shape|
  kind = (shape.kinds - [:nil]).to_a
  types = declared.fetch(name, []).uniq
  expected = kind == [:text] ? [M::Slice] : types.reject { |t| t == M::Slice }
  failures << "capture #{name} (#{kind.join('|')}) declared as #{types.map(&:name).inspect}" if types.empty? || types != expected
end
(declared.keys - shapes.captures.keys).each { |name| failures << "attribute #{name} is not a capture of the artifact" }

corpus = JSON.parse(File.read(Asciiunits::CORPUS_PATH, encoding: "UTF-8"))
artifact = Asciiunits.load_artifact
unless corpus.fetch("artifact_checksum") == JSON.parse(File.binread(Asciiunits::ARTIFACT_PATH)).fetch("checksum")
  failures << "corpus artifact_checksum #{corpus['artifact_checksum']} is not the artifact's"
end

accepted = rejected = 0
corpus.fetch("cases").each do |c|
  input = c.fetch("input")
  if c.fetch("kind") == "reject"
    begin
      Asciiunits.parse_model(input, artifact: artifact)
      failures << "#{input.inspect}: reject case parsed"
    rescue M::UndeclaredCapture => e
      failures << "#{input.inspect}: #{e.message}"
    rescue StandardError
      rejected += 1
    end
    next
  end

  expected = plain(c.fetch("parsanol_tree"))
  built = plain(JSON.parse(Asciiunits.parse_model(input, artifact: artifact).expression.to_json))
  failures << "#{input.inspect}: model of the parse differs from the recorded tree" unless built == expected
  round = plain(JSON.parse(M::Expression.from_json(JSON.generate(c.fetch("parsanol_tree"))).to_json))
  failures << "#{input.inspect}: recorded tree does not round-trip through the model" unless round == expected
  accepted += 1 if built == expected && round == expected
rescue StandardError => e
  failures << "#{input.inspect}: #{e.class}: #{e.message.lines.first}"
end

abort "model replay failures (#{failures.size}):\n#{failures.join("\n")}" unless failures.empty?
puts "model replay: #{accepted} accept cases equal, #{rejected} reject cases rejected, " \
     "#{shapes.captures.size} captures declared"
