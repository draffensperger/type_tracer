# frozen_string_literal: true
require 'spec_helper'

describe TypeTracer::TypeSampler, '#sampled_type_info' do
  it 'returns sampled method argument type info' do
    TypeTracer.config do |config|
      config.git_commit = 'test-commit'
      config.type_check_root_path = File.dirname(__FILE__)
      config.type_check_path_regex = /.*/
    end
    class Test
      def greeting(name)
        "Hi, #{name.upcase}!"
      end
    end
    sampler = TypeTracer::TypeSampler
    sampler.clear_sampled_type_info

    sampler.start
    Test.new.greeting('Joe')
    sampler.stop
    type_info = sampler.sampled_type_info

    expect(type_info[:git_commit]).to eq 'test-commit'
    types = type_info[:type_info]
    expect(types.keys).to eq [Test]
    test_types = types[Test]
    expect(test_types.keys).to eq [:greeting]
    greeting_types = test_types[:greeting]
    expect(greeting_types[:args]).to eq([[:req, :name]])
    expect(greeting_types[:arg_types]).to eq(name: { String => [:upcase] })
    expect(greeting_types[:callers].size).to eq 1
    expect(greeting_types[:callers].first.size).to eq 1
    expect(greeting_types[:callers].first.first).to match(/type_sampler_spec\.rb/)
  end
end
