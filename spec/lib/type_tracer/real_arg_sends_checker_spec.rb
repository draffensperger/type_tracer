# frozen_string_literal: true
require 'spec_helper'

describe TypeTracer::RealArgSendsChecker, '#invalid_arg_messages' do
  it 'returns an empty list if method would make no bad calls on args' do
    class Test
      def greet(name)
        puts name.upcase
      end
    end

    checker = TypeTracer::RealArgSendsChecker.new(Test, :greet, ['Joe'])

    expect(checker.invalid_arg_messages).to be_empty
  end

  it 'gives messages if method would make bad call on passed in arg' do
    class Test
      def greet(name)
        puts name.upcase
      end
    end

    checker = TypeTracer::RealArgSendsChecker.new(Test, :greet, [nil])

    expect(checker.invalid_arg_messages.size).to eq 1
  end
end
