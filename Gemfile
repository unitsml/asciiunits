# frozen_string_literal: true

source "https://rubygems.org"

# Build-time only: compiles the grammar and generates tables/oracle from the
# same terminal-selection code the Ruby parser uses. Runtime consumers need
# neither gem — they load artifacts/unitsml.json.
#
# Pinned to parsanol-ruby#361 until it releases: this branch compiles the
# grammar with `edition 2`, which no published parsanol understands yet.
# Switch back to "~> 1.3" once the release carrying #361 is cut.
gem "parsanol", github: "parsanol/parsanol-ruby", branch: "fix/v2-trivia-class"
gem "unitsml", github: "unitsml/unitsml-ruby", branch: "main"
gem "rake"
