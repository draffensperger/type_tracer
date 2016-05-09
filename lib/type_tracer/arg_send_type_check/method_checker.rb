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
        # For each argument to the method
        analyzer.arg_names.flat_map(&method(:bad_arg_sends)).compact
      end

      private

      def bad_arg_sends(arg)
        # For each of the sampled type classes for that argument
        @arg_types[arg].flat_map do |arg_type|
          bad_arg_sends_for_type(arg, arg_type[0])
        end
      end

      def bad_arg_sends_for_type(arg, arg_type)
        # Look up the sampled type class. We can do that because this runs with
        # the app environment loaded into it.
        type_class = Object.const_get(arg_type)

        # For each of the statically-analyzed send calls on that argument
        analyzer.arg_sends[arg].flat_map do |arg_send|
          # Check to see if the send call (in a locally changed method)
          # would be invalid based on the sampled type information (from the
          # method as it is deployed currently).
          next if instance_method?(type_class, arg_send)
          bad_arg_send_message(arg, type_class, arg_send)
        end
      end

      def analyzer
        @analyzer ||= MethodAnalyzer.new(method_def: @method_def)
      end

      def bad_arg_send_message(arg_name, arg_type, arg_send)
        source = @method_def.source_range
        "The method #{@class_sym}##{@method_sym} as type sampled may receive a "\
          "value of type #{arg_type} for the argument '#{arg_name}'. "\
          "However, that type (#{arg_type}) does not contain the instance "\
          "method '#{arg_send}' that the method tries to call on it. \n"\
          'Method location:'\
          "\n  #{source.source_buffer.name}:#{source.line}\n"
      end

      def instance_method?(klass, symbol)
        klass.instance_methods.include?(symbol) ||
          klass.private_instance_methods.include?(symbol)
      end
    end
  end
end
