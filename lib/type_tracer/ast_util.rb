module AstUtil
  def find_arg_sends(method_def)
    # If there is branching (as seen by :if and :case), then assume that the
    # branch may check the type of the arguments in which case making assumptions
    # about when an argument should be called with could be invalid.
    return {} if ast_find(method_def) { |node| [:if, :case].include?(node.type) }

    local_sends = local_var_sends(method_def)
    local_assigns = local_var_assigns(method_def)
    find_arg_names(method_def).map do |arg_name|
      if local_assigns.include?(arg_name)
        # If there are local variable assignments for the argument, then all bets
        # are off for comparing that the argument passsed in will actually get
        # called because the value of the argument could be overwritten.
        Set.new
      else
        local_sends[arg_name] || Set.new
      end
    end
  end

  def local_var_sends(method_def)
    locals_send_hash = {}

    local_var_send_nodes(method_def).map do |send_node|
      object, method_sym = send_node.children[0..1]
      local_var = object.children.first
      locals_send_hash[local_var] ||= Set.new
      locals_send_hash[local_var] << method_sym
    end

    locals_send_hash
  end

  def local_var_assigns(method_def)
    assigns = Set.new
    traverse_ast(method_def) do |node|
      assigns << node.children.first if node.type == :lvasgn
    end
    assigns
  end

  def local_var_send_nodes(method_def)
    ast_select(method_def) do |node|
      node.type == :send && node.children.first.type == :lvar
    end
  end

  def find_arg_names(method_def)
    args(method_def).children.map { |arg_node| arg_node.children.first }
  end

  def args(method_def)
    ast_find(method_def) do |node|
      node.type == :args
    end
  end

  def find_method_def(ast, method_symbol)
    ast_find(ast) do |node|
      node.type == :def && node.children.first == method_symbol
    end
  end

  def ast_find(ast, &_block)
    traverse_ast(ast) do |node|
      return node if yield(node)
    end
    nil
  end

  def ast_select(ast, &_block)
    found = []
    traverse_ast(ast) do |node|
      found << node if yield(node)
    end
    found
  end

  def traverse_ast(ast, &block)
    return unless ast && ast.is_a?(Parser::AST::Node)
    yield(ast)
    return unless ast.respond_to?(:children) && ast.children
    ast.children.find do |child|
      traverse_ast(child, &block)
    end
  end
end
