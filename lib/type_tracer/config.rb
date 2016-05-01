require 'singleton'

module TypeTracer
  class Config
    include Singleton

    attr_accessor :attribute_methods_definer
  end
end
