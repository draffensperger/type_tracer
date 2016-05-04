# frozen_string_literal: true
require_relative 'ast_util'

module TypeTracer
  class ArgSendTypeChecker
    include AstUtil

    def initialize(ast:, types:)
      @ast = ast
      @types = types
    end

    def bad_arg_sends
      method_defs.flat_map(&method(:method_bad_arg_sends))
    end

    private

    def method_defs
      @method_defs ||= @ast.each_descendant.select(&:def_type?)
    end

    def method_bad_arg_sends(_method_def)
      # arg_send_list = find_arg_sends(method_def)
      # return unless arg_send_list.present?
      # require 'pry'; binding.pry
      # arg_names = find_arg_names(method_def)
      # puts 'hi'
      []
    end

    def const_context(send_node)
      context_ancestors = send_node.each_ancestor.select do |ancestor|
        ancestor.class_type? || ancestor.module_type?
      end
      const_ancestors = context_ancestors.map { |n| n.children.first }
      const_path = const_ancestors.map { |n| n.children.second }
      Object.const_get(const_path.join('::'))
    end
  end
end
