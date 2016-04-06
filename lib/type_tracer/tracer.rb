require 'json'

module TypeTracer
  class Tracer
    def initialize(source_location_prefix)
      @source_location_prefix = source_location_prefix
      @method_call_types = {}
      @ignored_classes = Set.new
      @contracts = ContractsSet.new
    end

    # Allow this method to be big so that the majority of (ignored )traced
    # method calls will be able to be handled without more method calls.
    # rubocop:disable AbcSize
    def start_trace
      TracePoint.trace(:call) do |tp|
        next if tp.defined_class == self.class ||
                @ignored_classes.include?(tp.defined_class)

        method = tp.defined_class.instance_method(tp.method_id)
        unless method.source_location.first.start_with?(@source_location_prefix)
          @ignored_classes << tp.defined_class
          next
        end

        trace_method_call(tp)
      end
    end

    def types_hash
      result = {}

      @contracts.contracts.each do |type_context, type|
        result[type_context.klass] ||= {}
        result[type_context.klass][type_context.method] = format_type(type)
      end
      result
    end

    def types_json
      types_hash.to_json
    end

    private

    def format_type(type)
      type.klasses.map do |klass|
        { klass => type.klass_calls[klass].to_a }
      end
    end

    def trace_method_call(tp)
      tp.binding.local_variables.each do |var|
        value = tp.binding.local_variable_get(var)
        context = TypeContext.new(tp.defined_class, tp.method_id, var)
        watcher = TypeWatcher.new(value, @contracts, context)
        tp.binding.local_variable_set(var, watcher)
      end
    end
  end
end
