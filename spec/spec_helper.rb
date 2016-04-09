$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'type_tracer'
require 'active_support'
require 'parser/current'
require 'rspec/mocks'

class ArgCheckedInstanceDouble
  include AstUtil

  def initialize(instance_double)
    @instance_double = instance_double
    klass_name = instance_double.inspect.to_s.match(/\(([^)]*)\)/).captures.first
    @klass = ActiveSupport::Inflector.constantize(klass_name)
  end

  # rubocop:disable AbcSize
  # rubocop:disable MethodLength
  def method_missing(symbol, *args, &_block)
    file, _line = @klass.instance_method(symbol).source_location
    ruby_source = File.read(file)
    ast = Parser::CurrentRuby.parse(ruby_source)

    method_def = find_method_def(ast, symbol)
    arg_send_list = find_arg_sends(method_def)
    arg_names = find_arg_names(method_def)

    args.each_with_index do |arg_value, index|
      arg_sends = arg_send_list[index]
      next unless arg_sends
      arg_sends.each do |arg_send|
        next if arg_value.respond_to?(arg_send)
        raise "Called stubbed method #{@klass}##{symbol} with unrealistic "\
          "#{arg_names[index]} argument: #{arg_value.inspect}. "\
          "It should respond to #{arg_send.inspect} but it does not."
      end
    end

    @instance_double.send(symbol, *args)
  end

  attr_accessor :instance_double
end

def arg_checking_instance_double(*args)
  ArgCheckedInstanceDouble.new(instance_double(*args))
end
