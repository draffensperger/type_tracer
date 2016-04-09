require 'parser/current'
load './lib/type_tracer/ast_util.rb'

class MethodChecker
  include AstUtil

  def initialize(klass, symbol, signature)
    @klass = klass
    @symbol = symbol
    @signature = signature
  end

  def check
    file, _line = @klass.instance_method(@symbol).source_location
    ruby_source = File.read(file)
    ast = Parser::CurrentRuby.parse(ruby_source)
    method_def = find_method_def(ast, @symbol)
    arg_send_list = find_arg_sends(method_def)
    arg_names = find_arg_names(method_def)

    arg_names.each_with_index do |arg_name, arg_index|
      arg_signature = @signature[arg_name]
      next unless arg_signature
      arg_types = arg_signature.keys
      arg_sends = arg_send_list[arg_index]
      next unless arg_sends
      arg_types.each do |arg_type|
        arg_sends.each do |arg_send|
          next if arg_type.instance_methods.include?(arg_send)
          puts "The method #{@klass}##{@symbol} as type traced may receive a "\
            "value of type #{arg_type} for the argument #{arg_name} in "\
            "position #{arg_index}. However, that type (#{arg_type}) does not "\
            "contain the instance method #{arg_send} that the method tries to "\
            'call on it.'
        end
      end
    end
  end
end

class Hello
  def hi(x)
    x.downcase
  end
end

signature = {
  x: { String => [:is_a?, :downcase], Fixnum => [:is_a?, :+] }
}
MethodChecker.new(Hello, :hi, signature).check
