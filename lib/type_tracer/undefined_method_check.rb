require 'parser/current'
require 'active_support'
require_relative 'ast_util'

def defined_already
  puts 'hi'
end

class TestIt
  def hi1(_x)
    not_defined
  end

  def hi2
    hi1
    'A'.downcase
  end

  def h3
    defined_already
  end
end

module TypeTracer
  class UndefinedMethodCheck
    class << self
      include AstUtil

      def check_for_undefined_methods(source)
        ast = Parser::CurrentRuby.parse(source)
        method_definitions(ast).each do |method_def|
          base_level_sends(method_def).each do |base_level_send|
            klass = TestIt
            unless klass.instance_methods.include?(base_level_send) ||
                   klass.private_instance_methods.include?(base_level_send)
              puts "Undefined method: #{base_level_send} in #{method_def}"
            end
          end
        end
      end
    end
  end

  code = <<-EOS
  def defined_already
    puts "hi"
  end

  class TestIt
    def hi1(x)
      not_defined
    end

    def hi2
      hi1
      'A'.downcase
    end

    def h3
      defined_already
    end
  end
  EOS

  UndefinedMethodCheck.check_for_undefined_methods(code)
end
