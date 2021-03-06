# frozen_string_literal: true
module TypeTracer
  class RealArgSendsChecker
    def initialize(klass, symbol, args)
      @klass = klass
      @symbol = symbol
      @args = args
    end

    def invalid_arg_messages
      @args.each_with_index.flat_map(&method(:message_if_invalid_arg)).compact
    end

    private

    # arg_value is the real argument value that we would be calling this method
    # with (based on the method call on the stub).
    # index is the argument's position in the call
    def message_if_invalid_arg(arg_value, index)
      arg_sends = method_analyzer.arg_sends.values[index]
      return unless arg_sends

      # arg_sends is the list of definite method calls on that argument that
      # the static analyzer detected. If there are branches in the method or
      # assignments to that argument in the method, the analyzer is conservative
      # and doesn't assume that the sends will necessarily be on this value.
      arg_sends.each do |arg_send|
        next if arg_value.respond_to?(arg_send)

        # Give an invalid arg message if the arg doesn't respond to the call
        # that the stubbed method would make on it.
        return invalid_arg_message(arg_value, arg_send, index)
      end
      nil
    end

    def invalid_arg_message(arg_value, arg_send, index)
      "Called stubbed method #{@klass}##{@symbol} with unrealistic "\
        "'#{method_analyzer.arg_names[index]}' argument: #{arg_value.inspect}. "\
        "It should respond to #{arg_send.inspect} but it does not."
    end

    def method_analyzer
      @method_analyzer ||= MethodAnalyzer.new(method_def: method_ast)
    end

    def method_ast
      @method_ast ||=
        begin
          file, _line = @klass.instance_method(@symbol).source_location
          ast = TypeTracer.parse_file(file)
          find_method_def(ast, @symbol)
        end
    end

    def find_method_def(ast, method_symbol)
      ast.each_descendant.find do |node|
        node.def_type? && node.children.first == method_symbol
      end
    end
  end
end
