# frozen_string_literal: true

require "json"
require "set"

# Static capture shapes of the compiled artifact (artifacts/unitsml.json):
# for every capture name, the kinds of value the parsanol tree can hold
# under it and, for hash captures, the keys it can hold. Computed from the
# artifact's atom graph, not from samples, so a key the corpus never
# exercises is still declared. Used by scripts/generate_model.rb and
# scripts/replay_model.rb. Not part of the gem.
#
# Tree rules (parsanol-tree/v2, edition 2):
#   Str, Re               text
#   Lookahead             nil
#   Named(name, atom)     a hash with the one key +name+
#   Sequence              the merged keys of its hash parts; text when no
#                         part is a hash
#   Alternative           the union of its alternatives
#   Repetition max 1      its atom, or nil
#   Repetition            a list when its atom is a hash, else text
#   Entity                the atom it references
class CaptureShapes
  Shape = Struct.new(:kinds, :keys) do
    def self.of(*kinds) = new(Set.new(kinds), Set.new)

    def |(other) = Shape.new(kinds | other.kinds, keys | other.keys)
  end

  attr_reader :captures, :root

  def initialize(artifact_path, entry: "expression")
    grammar = JSON.parse(File.read(artifact_path, encoding: "UTF-8"))
                  .fetch("entries").fetch(entry).fetch("grammar")
    @atoms = grammar.fetch("atoms")
    @root_atom = grammar.fetch("root")
    solve
  end

  private

  # Recursive rules make one pass insufficient: iterate until no shape
  # grows. A reference to an atom under evaluation reads its last value.
  def solve
    @memo = {}
    @captures = {}
    loop do
      before = [@memo.dup, @captures.to_h]
      @captures = Hash.new { |h, k| h[k] = Shape.of }
      @done = Set.new
      @visiting = Set.new
      @atoms.each_index { |i| shape(i) }
      @root = shape(@root_atom)
      break if [@memo, @captures.to_h] == before
    end
    @captures = @captures.sort.to_h
  end

  def shape(index)
    return @memo.fetch(index, Shape.of) if @visiting.include?(index) || @done.include?(index)

    @visiting << index
    type, atom = @atoms.fetch(index).first
    result = evaluate(type, atom)
    @visiting.delete(index)
    @done << index
    @memo[index] = result
  end

  def evaluate(type, atom)
    case type
    when "Str", "Re" then Shape.of(:text)
    when "Lookahead" then Shape.of(:nil)
    when "Entity" then shape(atom.fetch("atom"))
    when "Named" then named(atom.fetch("name"), shape(atom.fetch("atom")))
    when "Alternative" then atom.fetch("atoms").map { |i| shape(i) }.reduce(Shape.of, :|)
    when "Sequence" then sequence(atom.fetch("atoms").map { |i| shape(i) })
    when "Repetition" then repetition(atom, shape(atom.fetch("atom")))
    else raise ArgumentError, "unknown atom type #{type}"
    end
  end

  def named(name, value)
    @captures[name] = @captures[name] | value
    Shape.new(Set[:hash], Set[name])
  end

  def sequence(parts)
    hashes = parts.select { |s| s.kinds.include?(:hash) }
    return Shape.new(Set[:hash], hashes.map(&:keys).reduce(Set.new, :|)) unless hashes.empty?
    return Shape.of(:text) if parts.any? { |s| s.kinds.include?(:text) }

    parts.reduce(Shape.of, :|)
  end

  def repetition(atom, value)
    return value | Shape.of(:nil) if atom["max"] == 1
    return Shape.new(Set[:list], value.keys) if value.kinds.include?(:hash)

    value
  end
end
