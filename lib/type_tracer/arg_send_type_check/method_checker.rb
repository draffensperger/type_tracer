# frozen_string_literal: true
module TypeTracer
  module ArgSendTypeCheck
    class MethodChecker
      def initialize(method_def:, method_sym:, class_sym:, arg_types:)
        @method_def = method_def
        @method_sym = method_sym
        @class_sym = class_sym
        @arg_types = arg_types
      end

      def bad_arg_send_messages
        analyzer.arg_names.flat_map do |arg|
          @arg_types[arg].flat_map do |arg_type|
            type_class = Object.const_get(arg_type[0])
            analyzer.arg_sends[arg].flat_map do |arg_send|
              next if instance_method?(type_class, arg_send)
              bad_arg_send_message(arg, type_class, arg_send)
            end
          end
        end.compact
      end

      private

      def analyzer
        @analyzer ||= MethodAnalyzer.new(method_def: @method_def)
      end

      def bad_arg_send_message(arg_name, arg_type, arg_send)
        "The method #{@class_sym}##{@method_sym} as type sampled may receive a "\
          "value of type #{arg_type} for the argument '#{arg_name}'. "\
          "However, that type (#{arg_type}) does not contain the instance "\
          "method '#{arg_send}' that the method tries to call on it."
      end

      def instance_method?(klass, symbol)
        klass.instance_methods.include?(symbol) ||
          klass.private_instance_methods.include?(symbol)
      end
    end
  end
end
