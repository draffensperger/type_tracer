# frozen_string_literal: true
require_relative 'ast_util'

module TypeTracer
  class ArgSendTypeChecker
    def initialize(ast:, types:)
      @ast = ast
      @types = types
    end

    def bad_arg_sends
      method_defs.flat_map(&method(:method_bad_arg_sends))
    end

    private

    def method_defs
      @ast.each_descendant.select(&:def_type?)
    end

    def method_bad_arg_sends(method_def)
      klass_sym = method_class_sym(method_def)
      method_sym = method_def.children.first

      types = @types[klass_sym][method_sym][:arg_types]
      analyzer = MethodAnalyzer.new(method_def: method_def)
      analyzer.arg_names.flat_map do |arg|
        types[arg].flat_map do |arg_type|
          type_klass = Object.const_get(arg_type[0])
          analyzer.arg_sends[arg].flat_map do |arg_send|
            next if has_instance_method?(type_klass, arg_send)
            bad_arg_send_message(method_def)
          end
        end
      end.compact
      # arg_send_list = find_arg_sends(method_def)
      # return unless arg_send_list.present?
      # require 'pry'; binding.pry
      # arg_names = find_arg_names(method_def)
      # puts 'hi'
      []
    end

    def bad_arg_send_message(_klass_sym, _method_sym, arg_name, arg_type)
      "The method #{@klass}##{@symbol} as type traced may receive a "\
        "value of type #{arg_type} for the argument #{arg_name} in "\
        "position #{arg_index}. However, that type (#{arg_type}) does not "\
        "contain the instance method #{arg_send} that the method tries to "\
        'call on it.'
    end

    def has_instance_method?(klass, symbol)
      klass.instance_methods.include?(symbol) ||
        klass.private_instance_methods.include?(symbol)
    end

    def method_type_info(method_def)
    end

    def method_class_sym(method_def)
      context_ancestors = method_def.each_ancestor.select do |ancestor|
        ancestor.class_type? || ancestor.module_type?
      end
      const_ancestors = context_ancestors.map { |n| n.children.first }
      const_path = const_ancestors.map { |n| n.children[1] }
      const_path.join('::').to_sym
    end
  end
end
