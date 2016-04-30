module RSpec
  module Mocks
    class VerifyingMethodDouble
      alias orig_proxy_method_invoked proxy_method_invoked

      def proxy_method_invoked(obj, *args, &block)
        orig_proxy_method_invoked(obj, *args, &block)
        return unless obj.is_a?(RSpec::Mocks::InstanceVerifyingDouble)

        name = @method_reference.instance_variable_get('@method_name')
        klass = @method_reference.instance_variable_get('@object_reference')
                                 .instance_variable_get('@object')

        checker = TypeTracer::ArgSendsChecker.new(klass, name, args)
        messages = checker.invalid_arg_messages
        return if messages.empty?
        raise RSpec::Mocks::MockExpectationError.new, messages.join("\n")
      end
    end
  end
end
