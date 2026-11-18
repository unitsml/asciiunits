# frozen_string_literal: true

require "lutaml/model"

module Asciiunits
  # The typed AsciiUnits model Asciiunits.parse_model returns, declared with
  # LutaML Model. The node classes are generated from the artifact's capture
  # shapes (scripts/generate_model.rb -> lib/asciiunits/model/nodes.rb);
  # Document is below. Every node holds exactly the parsanol tree it was
  # built from: a capture the model does not declare raises instead of
  # being dropped.
  module Model
    # A tree key the model does not declare, or a value of another kind.
    class UndeclaredCapture < StandardError; end
  end
end

require_relative "model/nodes"

module Asciiunits
  module Model
    # The result of one parse: the expression tree.
    class Document < Lutaml::Model::Serializable
      attribute :expression, "Asciiunits::Model::Expression"
    end

    module_function

    # Every model class, in name order.
    def classes
      constants.sort.map { |c| const_get(c) }
               .select { |k| k.is_a?(Class) && k < Lutaml::Model::Serializable }
    end

    # Builds the Document of a parsanol tree (Artifact#parse output).
    def from_tree(tree)
      Document.new(expression: node(Expression, tree))
    end

    def node(klass, tree)
      unless tree.is_a?(Hash)
        raise UndeclaredCapture, "#{klass.name} expects a hash, not #{tree.inspect[0, 80]}"
      end

      values = tree.each_with_object({}) do |(key, value), out|
        next if value.nil?

        attribute = klass.attributes[key.to_sym]
        raise UndeclaredCapture, "#{klass.name} declares no capture #{key}" unless attribute

        out[key.to_sym] = attribute.type == Slice ? slice(key, value) : node(attribute.type, value)
      end
      klass.new(**values)
    end

    def slice(key, value)
      unless value.respond_to?(:line_and_column)
        raise UndeclaredCapture, "capture #{key} expects a slice, not #{value.inspect[0, 80]}"
      end

      line, column = value.line_and_column
      Slice.new(value: value.to_s, offset: value.offset, length: value.length, line: line, column: column)
    end

    private_class_method :node, :slice
  end
end
