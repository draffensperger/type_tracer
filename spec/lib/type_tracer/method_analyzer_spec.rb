# frozen_string_literal: true
require 'spec_helper'

describe TypeTracer::MethodAnalyzer do
  it 'returns empty list if method has no sends on args' do
    ast = TypeTracer.parse(<<-EOS)
    def hello(x)
      puts x
    end
    EOS
    analyzer = TypeTracer::MethodAnalyzer.new(method_def: ast)

    expect(analyzer.arg_names).to eq([:x])
    expect(analyzer.arg_sends).to eq(x: [])
  end

  it 'returns direct send calls on args' do
    ast = TypeTracer.parse(<<-EOS)
    def hello(x)
      x.odd? || x.zero? || x.odd?
    end
    EOS
    analyzer = TypeTracer::MethodAnalyzer.new(method_def: ast)

    expect(analyzer.arg_sends).to eq(x: [:odd?, :zero?])
  end

  it 'does not return direct send calls on non-arg local variables' do
    ast = TypeTracer.parse(<<-EOS)
    def hello
      x = 2
      x.even?
    end
    EOS
    analyzer = TypeTracer::MethodAnalyzer.new(method_def: ast)

    expect(analyzer.arg_sends).to eq({})
  end

  it 'returns an empty list if there is a branch in the method' do
    ast = TypeTracer.parse(<<-EOS)
    def hello(x)
      x.odd? if x.is_a?(Fixnum)
    end
    EOS
    analyzer = TypeTracer::MethodAnalyzer.new(method_def: ast)

    expect(analyzer.arg_sends).to eq(x: [])
  end

  it 'returns an empty list if an argument gets assigned a value' do
    ast = TypeTracer.parse(<<-EOS)
    def hello(x)
      x = 3
      x.odd?
    end
    EOS
    analyzer = TypeTracer::MethodAnalyzer.new(method_def: ast)

    expect(analyzer.arg_sends).to eq(x: [])
  end
end
