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
      # For the simple version, just assume we don't know what will happen if
      # there are branches in the method, so assume that no args definitely get
      # called (as there could be conditioning on arg type).
      return empty_arg_sends if branches?
      Hash[arg_names.map { |arg| [arg, sends_for_arg(arg)] }]
    end

    private

    def branches?
      @method_def.each_descendant.any? { |node| node.if_type? || node.case_type? }
    end

    def empty_arg_sends
      Hash[arg_names.map { |n| [n, []] }]
    end

    def sends_for_arg(arg)
      if local_var_assigns.include?(arg)
        []
      else
        local_var_sends[arg].to_a
      end
    end

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

    def local_var_assigns
      return @local_var_assigns if @local_var_assigns
      @local_var_assigns = Set.new
      @method_def.each_descendant do |node|
        @local_var_assigns << node.children.first if node.lvasgn_type?
      end
      @local_var_assigns
    end

    def local_var_send_nodes
      @method_def.each_descendant.select do |node|
        node.children && node.children.first && node.send_type? &&
          node.children.first.lvar_type?
      end
    end
  end
end
