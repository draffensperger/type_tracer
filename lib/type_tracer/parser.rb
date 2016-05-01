require 'rubocop'
require 'parser/current'
Parser::Builders::Default.emit_lambda = true

module TypeTracer
  class << self
    def parse_file(file)
      parse(File.read(file), file)
    end

    def parse(source, filename = '(string)')
      buffer = Parser::Source::Buffer.new(filename)
      buffer.source = source

      builder = RuboCop::Node::Builder.new
      parser = Parser::CurrentRuby.new(builder)
      parser.parse(buffer)
    end
  end
end
