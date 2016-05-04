# frozen_string_literal: true
module TypeTracer
  class MethodAnalyzer
    def initialize(method_def:)
      @method_def = method_def
    end

    def arg_names
      args.children.map { |arg_node| arg_node.children.first }
    end

    def arg_sends
      Hash[arg_names.map { |arg| [arg, local_var_sends[arg].to_a] }]
    end

    private

    def args
      @method_def.each_descendant.find(&:args_type?)
    end

    def local_var_sends
      return @local_var_sends if @local_var_sends
      @local_var_sends = {}

      local_var_send_nodes.map do |send_node|
        object, method_sym = send_node.children[0..1]
        local_var = object.children.first
        @local_var_sends[local_var] ||= Set.new
        @local_var_sends[local_var] << method_sym
      end

      @local_var_sends
    end

    def local_var_send_nodes
      @method_def.each_descendant.select do |node|
        node.children && node.children.first && node.send_type? &&
          node.children.first.lvar_type?
      end
    end
  end
end
