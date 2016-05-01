require 'type_tracer/parser'

module TypeTracer
  class InstanceMethodChecker
    def initialize(source_text, filename, output_stream)
      @source_text = source_text
      @filename = filename
      @stream = output_stream
    end

    def check_instance_methods
      self_sends.any?(&method(:check_self_send))
    end

    private

    def ast
      @ast ||= TypeTracer.parse(@source_text, @filename)
    end

    def self_sends
      ast.each_descendant.select do |node|
        node.send_type? && node.children.first.nil?
      end
    end

    def check_self_send(send_node)
      symbol = send_node.children.second

      # private/protected specifiers are parsed as a send, so just ignore them
      return if symbol == :private || symbol == :protected

      klass = const_context(send_node)
      return if klass.instance_methods.include?(symbol) ||
                klass.private_instance_methods.include?(symbol) ||
                klass.respond_to?(symbol)

      @stream.puts "Likely undefined method: #{symbol} for #{klass} instance"\
        "\n  in #{@filename}:#{send_node.source_range.line}\n\n"

      true
    end

    def const_context(send_node)
      context_ancestors = send_node.each_ancestor.select do |ancestor|
        ancestor.class_type? || ancestor.module_type?
      end
      const_ancestors = context_ancestors.map { |n| n.children.first }
      const_path = const_ancestors.map { |n| n.children.second }
      Object.const_get(const_path.join('::'))
    end
  end
end
