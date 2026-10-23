# frozen_string_literal: true

# unitsml gem terminal selection -> tables/*.yaml
#
# Mirrors lib/unitsml/parse.rb exactly: units.filtered, prefixes_by_size(1/2),
# dimensions.parsables.keys. Deterministic ordering (length desc, then
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

write_table("units", Unitsml::Unitsdb.units.filtered)
write_table("prefixes_single", Unitsml::Unitsdb.prefixes_by_size(1))
write_table("prefixes_double", Unitsml::Unitsdb.prefixes_by_size(2))
write_table("dimensions", Unitsml::Unitsdb.dimensions.parsables.keys)
