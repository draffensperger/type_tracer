# frozen_string_literal: true

module TypeTracer
  module ArgSendTypeCheck
    class AstChecker
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
        class_sym = method_class_sym(method_def)
        method_sym = method_def.children.first

        arg_types = @types[class_sym][method_sym][:arg_types]
        MethodChecker.new(method_def: method_def, method_sym: method_sym,
                          class_sym: class_sym, arg_types: arg_types)
                     .bad_arg_send_messages
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
end
