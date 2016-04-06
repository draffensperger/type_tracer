class SingleParamCaller
  def call(object)
    if object.is_a?(String)
      object.downcase
    else
      object + 1
    end
  end
end

SingleParamCaller.new.call('A')
SingleParamCaller.new.call(1)
