require 'delegate'
require 'type_tracer/type_watcher'

module TypeTracer
  class TypeSampler
    class << self
      # The block in the method_info below will be called on every Ruby method_info call, so
      # try to minimize how many method_info call it itself makes.
      def start
        @source_location_prefix ||= TypeTracer.config.type_sampler_root_path.to_s
        @ignored_classes ||= Set.new
        @type_info_by_class ||= {}

        @trace = TracePoint.new(:call) do |tp|
          klass = tp.defined_class
          next if klass == self.class || @ignored_classes.include?(klass)
          begin
            method_info = klass.instance_method(tp.method_id)
          rescue
            # If the class doesn't support querying an instance method_info based
            # on a symbol, just skip it.
            next
          end

          unless method_info.source_location[0].start_with?(@source_location_prefix)
            @ignored_classes << klass
            next
          end

          add_sampled_type_info(tp, method_info, caller)
        end

        @trace.enable
      end

      def stop
        return unless @trace && @trace.enabled?
        @trace.disable
      end

      def sampled_type_info
        @type_info_by_class
      end

      private

      def add_sampled_type_info(tp, method_info, method_caller)
        klass = tp.defined_class
        @type_info_by_class[klass] ||= {}
        class_type_info = @type_info_by_class[klass]

        args = method_info.parameters
        arg_names = args.map(&:second)
        class_type_info[tp.method_id] ||= {
          args: args,
          arg_types: {},
          callers: []
        }
        method_type_info = class_type_info[tp.method_id]

        call_stack = project_call_stack(method_caller)

        unless method_type_info[:callers].include?(call_stack)
          method_type_info[:callers] << call_stack
        end

        add_arg_type_info(tp, method_type_info[:arg_types], arg_names)
      end

      def add_arg_type_info(tp, args_type_info, arg_names)
        tp.binding.local_variables.each do |arg|
          next unless arg_names.include?(arg)
          args_type_info[arg] ||= {}
          arg_type_info = args_type_info[arg]

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

      def project_call_stack(method_caller)
        selected_caller = method_caller[1..-1].select do |frame|
          frame.start_with?(@source_location_prefix)
        end
        selected_caller.map! { |frame| frame[@source_location_prefix.length..-1] }
      end
    end
  end
end
