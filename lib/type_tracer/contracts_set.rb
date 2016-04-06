module TypeTracer
  class ContractsSet
    attr_accessor :contracts

    def initialize
      @contracts = {}
    end

    def type_for(type_context)
      contracts[type_context] ||= Type.new
      contracts[type_context]
    end
  end
end
