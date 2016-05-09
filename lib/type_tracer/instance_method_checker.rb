# frozen_string_literal: true
require 'type_tracer/parser'

module TypeTracer
  class InstanceMethodChecker
    def initialize(ast)
      @ast = ast
    end

    def undefined_method_messages
      self_sends.map(&method(:bad_self_send_messages)).compact
    end

    private

    def self_sends
      @ast.each_descendant.select do |node|
        node.send_type? && node.children.first.nil?
      end
    end

    def bad_self_send_messages(send_node)
      symbol = send_node.children[1]

      # private/protected specifiers are parsed as a send, so just ignore them
      # define_method also doesn't get listed as a method but is one!
      return if [:private, :protected, :define_method].include?(symbol)

      # Look up the class for the AST send node in the loaded Ruby
      # environment. We can do that because this is being run in a Rake
      # rask with the loaded app environment.
      klass = loaded_class(send_node)
      return if klass.instance_methods.include?(symbol) ||
                klass.private_instance_methods.include?(symbol) ||
                klass.respond_to?(symbol)

      # The abstract syntax tree keeps a reference to the node's file/line
      source = send_node.source_range
      "Likely undefined method: #{symbol} for #{klass} instance"\
        "\n  in #{source.source_buffer.name}:#{source.line}\n\n"
    end

    def loaded_class(send_node)
      context_ancestors = send_node.each_ancestor.select do |ancestor|
        ancestor.class_type? || ancestor.module_type?
      end
      const_ancestors = context_ancestors.map { |n| n.children.first }
      const_path = const_ancestors.map { |n| n.children[1] }
      Object.const_get(const_path.join('::'))
    end
  end
end
