# frozen_string_literal: true
require 'type_tracer/type_fetcher'
require 'type_tracer/arg_send_type_checker'

module TypeTracer
  class ArgSendTypeCheckRunner
    def initialize(files, stream)
      @files = files
      @stream = stream
    end

    def check_args
      @files.all? do |file|
        ArgSendTypeChecker.new(file, filter_types, @stream).check_arg_sends
      end
    end

    private

    def changed_files
      @changed_files ||=
        `git diff --name-only #{fetched_types[:git_commit]} HEAD`.split("\n")
    end

    def fetched_types
      @fetched_types ||= TypeFetcher.fetch_sampled_types
    end

    def filtered_types
      @filtered_types ||= filter_types
    end

    def filter_types
      type_info = fetched_types[:type_info]
      type_info.each do |klass_sym, method_types|
        method_types.each do |method_sym, method_type_info|
          # All the callers of this method have at least one file changed, so
          # assume that this method type signature may no longer be valid.
          if all_have_changed_file(method_type_info[:callers])
            # Remove it from the type list
            type_info[klass_sym].delete(method_sym)
          end
        end
      end
    end

    def all_have_changed_file(call_stacks)
      call_stacks.all? do |call_stack|
        stack_files = call_stack.map { |frame| frame.split(':')[0] }
        !(stack_files & changed_files).empty?
      end
    end
  end
end
