# frozen_string_literal: true
require 'spec_helper'

# We use eval to load code snippets that we also parse to avoid needing to
# create fixture files for short bits of code.
# rubocop:disable Eval

describe TypeTracer::InstanceMethodChecker, '#undefined_method_messages' do
  it 'returns an empty list if no undefined instance methods' do
    code = <<-EOS
    class Test
      def hi
        puts "hi"
      end
    end
    EOS
    eval(code)
    ast = TypeTracer.parse(code)

    messages = TypeTracer::InstanceMethodChecker.new(ast).undefined_method_messages

    expect(messages).to be_empty
  end

  it 'properly considers dynamically defined methods' do
    code = <<-EOS
    class Test
      def hi
        greet
      end

      define_method(:greet) do
        puts "hi"
      end
    end
    EOS
    eval(code)
    ast = TypeTracer.parse(code)

    messages = TypeTracer::InstanceMethodChecker.new(ast).undefined_method_messages

    expect(messages).to be_empty
  end

  it 'returns messages for undefined instance methods' do
    code = <<-EOS
    class Test
      def hi
        undefined_method!
      end
    end
    EOS
    eval(code)
    ast = TypeTracer.parse(code)

    messages = TypeTracer::InstanceMethodChecker.new(ast).undefined_method_messages

    expect(messages.size).to eq 1
  end
end
