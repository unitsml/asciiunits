# frozen_string_literal: true

source "https://rubygems.org"

# Build-time only: compiles the grammar and generates tables/oracle from the
# same terminal-selection code the Ruby parser uses. Runtime consumers need
# neither gem — they load artifacts/unitsml.json.
gem "parsanol", "~> 1.3"
gem "unitsml", github: "unitsml/unitsml-ruby", branch: "parg-parser"
gem "rake"
