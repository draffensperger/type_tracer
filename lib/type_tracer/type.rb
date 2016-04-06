module TypeTracer
  class Type
    attr_accessor :klasses, :klass_calls

    def initialize
      @klasses = Set.new
      @klass_calls = {}
    end

    def record_object(object)
      klasses << object.class
    end

    def record_call(object, method)
      klass = object.class
      klass_calls[klass] ||= Set.new
      klass_calls[klass] << method
    end
  end
end
