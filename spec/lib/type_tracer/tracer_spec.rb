require 'spec_helper'

module TypeTracer
  describe Tracer, '#trace' do
    it 'traces type of method calls' do
      fixture_file = 'spec/fixtures/simple_call.rb'
      tracer = Tracer.new(fixture_file)
      tracer.start_trace

      load(fixture_file)

      expect(tracer.types_hash).to eq(
        SingleParamCaller => {
          call: {
            object: { String => [:is_a?, :downcase], Fixnum => [:is_a?, :+] }
          }
        }
      )

      expect(tracer.types_json).to eq(
        '{"SingleParamCaller":{"call":'\
        '{"object":{"String":["is_a?","downcase"],"Fixnum":["is_a?","+"]}}}}'
      )
    end
  end
end
