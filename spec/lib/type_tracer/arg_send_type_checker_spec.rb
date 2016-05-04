# frozen_string_literal: true
require 'spec_helper'

describe TypeTracer::FileArgSendTypeChecker, '#check_arg_sends' do
  it 'returns an empty list if there are no invalid sends' do
    ast = TypeTracer.parse(<<-EOS)
    def empty_method
    end
    EOS
    types = {}

    bad_arg_sends = TypeTracer::FileArgSendTypeChecker
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

    bad_arg_sends = TypeTracer::FileArgSendTypeChecker
                    .new(ast: ast, types: types).bad_arg_sends

    msg = 'The method Test#hello as type sampled may receive a value of type '\
      "Fixnum for the argument 'x'. However, that type (Fixnum) does not contain "\
      "the instance method 'downcase' that the method tries to call on it."
    expect(bad_arg_sends).to eq([msg])
  end
end
