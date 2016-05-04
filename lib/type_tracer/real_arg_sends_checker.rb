# frozen_string_literal: true
require 'parser/current'
require_relative 'ast_util'

module TypeTracer
  class RealArgSendsChecker
    include AstUtil

    def initialize(klass, symbol, args)
      @klass = klass
      @symbol = symbol
      @args = args
    end

    def invalid_arg_messages
      @args.each_with_index.flat_map(&method(:message_if_invalid_arg)).compact
    end

    private

    def message_if_invalid_arg(arg_value, index)
      arg_sends = arg_send_list[index]
      return unless arg_sends
      arg_sends.each do |arg_send|
        next if arg_value.respond_to?(arg_send)
        return invalid_arg_message(arg_value, arg_send, index)
      end
      nil
    end

    def invalid_arg_message(arg_value, arg_send, index)
      "Called stubbed method #{@klass}##{@symbol} with unrealistic "\
        "'#{arg_names[index]}' argument: #{arg_value.inspect}. "\
        "It should respond to #{arg_send.inspect} but it does not."
    end

    def arg_names
      @arg_names ||= find_arg_names(method_ast)
    end

    def arg_send_list
      @arg_send_list ||= find_arg_sends(method_ast)
    end

    def method_ast
      @method_ast ||=
        begin
          file, _line = @klass.instance_method(@symbol).source_location
          ruby_source = File.read(file)
          ast = Parser::CurrentRuby.parse(ruby_source)
          find_method_def(ast, @symbol)
        end
    end
  end
end
