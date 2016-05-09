# frozen_string_literal: true
require 'rspec/mocks'
require 'type_tracer'
require 'type_tracer/real_arg_sends_checker'

module RSpec
  module Mocks
    class VerifyingMethodDouble
      alias orig_proxy_method_invoked proxy_method_invoked

      def proxy_method_invoked(obj, *args, &block)
        orig_proxy_method_invoked(obj, *args, &block)
        return unless obj.is_a?(InstanceVerifyingDouble)

        name = @method_reference.instance_variable_get('@method_name')
        klass = @method_reference.instance_variable_get('@object_reference')
                                 .instance_variable_get('@object')

        checker = TypeTracer::RealArgSendsChecker.new(klass, name, args)
        messages = checker.invalid_arg_messages
        raise MockExpectationError.new, messages.join("\n") unless messages.empty?
      end
    end
  end
end
