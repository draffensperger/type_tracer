require 'delegate'
require 'type_tracer/type_watcher'

module TypeTracer
  class TypeSampler
    class << self
      # The block in the method below will be called on every Ruby method call, so
      # try to minimize how many method call it itself makes.
      # rubocop:disable AbcSize
      # rubocop:disable MethodLength
      # rubocop:disable CyclomaticComplexity
      def start
        @source_location_prefix ||= TypeTracer.config.type_sampler_root_path.to_s
        @ignored_classes ||= Set.new
        @type_info_by_class ||= {}

        @trace = TracePoint.new(:call) do |tp|
          klass = tp.defined_class
          next if klass == self.class || @ignored_classes.include?(klass)
          begin
            method = klass.instance_method(tp.method_id)
          rescue
            # If the class doesn't support querying an instance method based
            # on a symbol, just skip it.
            next
          end

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

            #  We can only do do a delegate-based type watching on truthy
            #  values because it's not possible to turn a custom object into a
            #  falsely value in Ruby
            next unless value && !value.is_a?(Fixnum)
            watcher = TypeWatcher.new(value, arg_type_info[value_klass])
            tp.binding.local_variable_set(arg, watcher)
          end
        end

        @trace.enable
      end

      def stop
        return unless @trace && @trace.enabled?
        @trace.disable
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
end
