require 'delegate'
require 'type_tracer/type_watcher'

module TypeTracer
  class TypeSampler
    class << self
      def start
        @project_root ||= TypeTracer.config.type_sampler_root_path.to_s + '/'
        @sample_path_regex ||= TypeTracer.config.type_sampler_path_regex
        @ignored_classes ||= Set.new
        @type_info_by_class ||= {}
        @trace ||= TracePoint.new(:call, &method(:trace_method_call))
        @trace.enable
      end

      def stop
        return unless @trace && @trace.enabled?
        @trace.disable
      end

      def sampled_type_info
        {
          git_commit: TypeTracer.config.git_commit,
          type_info: @type_info_by_class
        }
      end

      private

      def trace_method_call(tp)
        klass = tp.defined_class

        # Skip if the method call is in this class or an ignored class
        return if klass == self.class || @ignored_classes.include?(klass)

        unbound_method = unbound_method_or_nil(tp)
        return unless unbound_method

        if in_sample_path?(unbound_method.source_location[0])
          add_sampled_type_info(tp, unbound_method)
        else
          @ignored_classes << klass
        end
      end

      def in_sample_path?(path)
        return false unless path.start_with?(@project_root)
        path[@project_root.size..-1] =~ @sample_path_regex
      end

      def unbound_method_or_nil(tp)
        tp.defined_class.instance_method(tp.method_id)
      rescue
        # Return nil if the defined class fails to provide `instance_method`
        nil
      end

      def add_sampled_type_info(tp, unbound_method)
        method_info = find_method_info(tp, unbound_method)

        add_project_call_stack(method_info[:callers])
        add_args_type_info(tp, method_info[:arg_types], method_info[:arg_names])
      end

      def find_method_info(tp, unbound_method)
        klass = tp.defined_class
        @type_info_by_class[klass] ||= {}
        class_type_info = @type_info_by_class[klass]
        class_type_info[tp.method_id] ||= default_method_info(unbound_method)
      end

      def default_method_info(unbound_method)
        args = unbound_method.parameters
        {
          args: args,
          arg_names: args.map(&:second),
          arg_types: {},
          callers: []
        }
      end

      def add_project_call_stack(call_stacks)
        # Exclude non-project frames, and then also exclude the first project
        # frame as that frame is for the method call we are type sampling.
        stack = caller.select(&method(:in_sample_path?))[1..-1]
                .map { |f| f[@project_root.size..-1] }
        call_stacks << stack unless call_stacks.include?(stack)
      end

      def add_args_type_info(tp, args_type_info, arg_names)
        arg_local_vars = arg_names & tp.binding.local_variables

        arg_local_vars.each do |arg|
          args_type_info[arg] ||= {}
          add_arg_type_info(tp, args_type_info[arg], arg)
        end
      end

      def add_arg_type_info(tp, arg_type_info, arg)
        value = tp.binding.local_variable_get(arg)
        value_klass = value.class

        arg_type_info[value_klass] ||= []

        # We can only do do a delegate-based type watching on truthy
        # values because it's not possible to turn a custom object into a
        # falsely value in Ruby
        return unless value && !value.is_a?(Fixnum)
        watcher = TypeWatcher.new(value, arg_type_info[value_klass])
        tp.binding.local_variable_set(arg, watcher)
      end
    end
  end
end
