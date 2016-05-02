class TypeWatcher < BasicObject
  def initialize(target, calls_list)
    @target = target
    @calls_list = calls_list
  end

  def method_missing(m, *args, &block)
    @calls_list << m unless @calls_list.include?(m)
    @target.__send__(m, *args, &block)
  end
end
