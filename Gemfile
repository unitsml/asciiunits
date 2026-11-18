# frozen_string_literal: true

source "https://rubygems.org"

# Build-time only: compiles the grammar and generates tables/oracle from the
# same terminal-selection code the Ruby parser uses. Runtime consumers need
# neither gem — they load artifacts/unitsml.json.
gem "parsanol", "~> 1.5.0"
# The typed model (lib/asciiunits/model.rb) and its LML export.
gem "lutaml-model", "~> 0.8", ">= 0.8.162"
gem "unitsml", github: "unitsml/unitsml-ruby", branch: "main"
gem "rake"
