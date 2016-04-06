require 'json'

module TypeTracer
  class Tracer
    def initialize(source_location_prefix)
      @source_location_prefix = source_location_prefix
      @ignored_classes = Set.new
      @type_info_by_class = {}
    end

    # The block in the method below will be called on every Ruby method call, so
    # try to minimize how many method call it itself makes.
    # rubocop:disable AbcSize
    # rubocop:disable MethodLength
    def start_trace
      TracePoint.trace(:call) do |tp|
        klass = tp.defined_class
        next if klass == self.class || @ignored_classes.include?(klass)
        method = klass.instance_method(tp.method_id)
        unless method.source_location[0].start_with?(@source_location_prefix)
          @ignored_classes << klass
          next
        end

        @type_info_by_class[klass] ||= {}
        class_type_info = @type_info_by_class[klass]

        class_type_info[tp.method_id] ||= {}
        method_type_info = class_type_info[tp.method_id]

        tp.binding.local_variables.each do |arg|
          method_type_info[arg] ||= {}
          arg_type_info = method_type_info[arg]

          value = tp.binding.local_variable_get(arg)
          value_klass = value.class

          arg_type_info[value_klass] ||= []
          watcher = TypeWatcher.new(value, arg_type_info[value_klass])
          tp.binding.local_variable_set(arg, watcher)
        end
      end
    end

    def types_hash
      @type_info_by_class
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
  end
end
