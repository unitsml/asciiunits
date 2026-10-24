# frozen_string_literal: true

# unitsml gem terminal selection -> tables/*.yaml
#
# Mirrors lib/unitsml/parse.rb exactly: units.filtered, prefixed_symbols,
# prefixes_by_size(1/2), dimensions.parsables.keys. Deterministic ordering (length desc, then
# alphabetical); the compiler expands from_table longest-first anyway.

require "bundler/setup"
require "yaml"
require "unitsml"

ROOT = File.expand_path("..", __dir__)

def write_table(name, tokens)
  sorted = tokens.map(&:to_s).uniq.sort_by { |t| [-t.length, t] }
  path = File.join(ROOT, "tables/#{name}.yaml")
  File.write(path, sorted.map { |t| { "name" => t } }.to_yaml)
  puts "tables/#{name}.yaml: #{sorted.size} tokens"
end

# Byte comparison fails across platforms: Psych versions wrap long strings
# differently. Compare the parsed token lists instead.
def check_table(name, tokens)
  sorted = tokens.map(&:to_s).uniq.sort_by { |t| [-t.length, t] }
  committed = YAML.safe_load(File.read(File.join(ROOT, "tables/#{name}.yaml")))
  expected = sorted.map { |t| { "name" => t } }
  abort "tables/#{name}.yaml stale — run `rake tables:gen` and commit" unless committed == expected
  puts "tables/#{name}.yaml: ok (#{sorted.size} tokens)"
end

tables = {
  "units" => Unitsml::Unitsdb.units.filtered,
  "prefixed_units" => Unitsml::Unitsdb.units.prefixed_symbols,
  "prefixes_single" => Unitsml::Unitsdb.prefixes_by_size(1),
  "prefixes_double" => Unitsml::Unitsdb.prefixes_by_size(2),
  "dimensions" => Unitsml::Unitsdb.dimensions.parsables.keys,
}

if ARGV.delete("--check")
  tables.each { |name, tokens| check_table(name, tokens) }
else
  tables.each { |name, tokens| write_table(name, tokens) }
end
