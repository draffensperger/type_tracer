class TypeWatcher < BasicObject
  def initialize(delegate, contracts_set, context)
    @contracts = contracts_set
    @delegate = delegate
    @context = context
    type.record_object(delegate)
  end

  def method_missing(symbol, *args, &_block)
    type.record_call(@delegate, symbol)
    @delegate.send(symbol, *args)
  end

  private

  def type
    @contracts.type_for(@context)
  end
end
