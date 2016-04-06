class TypeWatcher < BasicObject
  def initialize(delegate, calls_list)
    @delegate = delegate
    @calls_list = calls_list
  end

  def method_missing(symbol, *args, &_block)
    @calls_list << symbol unless @calls_list.include?(symbol)
    @delegate.send(symbol, *args)
  end
end
