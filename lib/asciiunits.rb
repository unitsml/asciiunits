# frozen_string_literal: true

require_relative "asciiunits/version"

module Asciiunits
  REPO_ROOT = File.expand_path("..", __dir__)
  ARTIFACT_PATH = File.join(REPO_ROOT, "artifacts/unitsml.json")
  TABLES_DIR = File.join(REPO_ROOT, "tables")
  GRAMMAR_PATH = File.join(REPO_ROOT, "grammars/unitsml.parg")
  CORPUS_PATH = File.join(REPO_ROOT, "corpora/unitsml/corpus.json")
  MODEL_PATH = File.join(REPO_ROOT, "model/asciiunits.lml.json")

  module_function

  # Loads the checksummed PARG artifact through the parsanol runtime.
  # The returned Parsanol::PARG::Artifact exposes parse, parse_and_bind,
  # parse_recovering and run_tests for the single entry "expression".
  def load_artifact
    require "parsanol"
    Parsanol::PARG::Artifact.load(ARTIFACT_PATH, tables_dir: TABLES_DIR)
  end

  # Parses +input+ with the artifact's "expression" entry and returns the
  # typed model (Asciiunits::Model::Document). Raises what Artifact#parse
  # raises on rejected input. Loads lutaml-model on first use; the
  # artifact is loaded once unless one is passed.
  def parse_model(input, artifact: (@artifact ||= load_artifact))
    require_relative "asciiunits/model"
    Model.from_tree(artifact.parse("expression", input))
  end
end
