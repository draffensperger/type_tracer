# frozen_string_literal: true
require 'spec_helper'

describe TypeTracer::ArgSendTypeChecker, '#check_arg_sends' do
  it 'returns an empty list if there are no invalid sends' do
    ast = TypeTracer.parse(<<-EOS)
    def empty_method
    end
    EOS
    types = {}

    bad_arg_sends = TypeTracer::ArgSendTypeChecker
                    .new(ast: ast, types: types).bad_arg_sends

    expect(bad_arg_sends).to be_empty
  end

  it 'returns invalid arg send info if types specify an incompatible arg type' do
    ast = TypeTracer.parse(<<-EOS)
    class Test
      def hello(x)
        x.downcase
      end
    end
    EOS
    types = {
      Test: {
        hello: {
          args: [%w(req x)],
          arg_types: {
            x: { Fixnum: [] }
          }
        }
      }
    }

    bad_arg_sends = TypeTracer::ArgSendTypeChecker
                    .new(ast: ast, types: types).bad_arg_sends

    expect(bad_arg_sends).to eq([''])
  end
end
