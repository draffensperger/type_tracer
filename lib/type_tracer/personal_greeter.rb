module TypeTracer
  class PersonalGreeter
    def initialize(name, greeter)
      @name = name
      @greeter = greeter
    end

    def greet
      # give nil for the default language
      language = nil
      @greeter.greet(@name, language)
    end
  end
end
