require 'rspec/mocks/standalone'
require 'spec_helper'

module TypeTracer
  class AutoTypeDouble
    include RSpec::Mocks::ExampleMethods

    def initialize(args)
      @double_args = args
      @wrapped_double = double(args)
    end

    def type=(type)
      puts "setting type of #{@wrapped_double} to #{type}"
      @wrapped_double = arg_checking_instance_double(type, @double_args)
      puts "set type of #{@wrapped_double} to #{type}"
    end

    def method_missing(symbol, *args, &_block)
      @wrapped_double.send(symbol, *args)
    end

    def wrapped_double
      if @wrapped_double.is_a?(ArgCheckedInstanceDouble)
        @wrapped_double.instance_double
      else
        @wrapped_double
      end
    end
  end

  $traced_types = {
    PersonalGreeter => {
      initialize: {
        name: { String => [] },
        greeter: { Greeter => [] }
      }
    }
  }

  class SpecTracer
    def initialize(source_location_prefix)
      @source_location_prefix = source_location_prefix
      @ignored_classes = Set.new
      @ignored_classes << AstUtil
      @type_info_by_class = {}
    end

    # The block in the method below will be called on every Ruby method call, so
    # try to minimize how many method call it itself makes.
    # rubocop:disable MethodLength
    # rubocop:disable CyclomaticComplexity
    # rubocop:disable AbcSize
    def start_trace
      TracePoint.trace(:call) do |tp|
        klass = tp.defined_class
        next if klass == self.class || @ignored_classes.include?(klass)
        method = klass.instance_method(tp.method_id)
        unless method.source_location[0].start_with?(@source_location_prefix)
          @ignored_classes << klass
          next
        end

        tp.binding.local_variables.each do |arg|
          value = tp.binding.local_variable_get(arg)
          value_klass = value.class
          p [tp.defined_class, tp.method_id, arg, value_klass, value]
          next unless value_klass == AutoTypeDouble
          puts 'auto type double!'
          puts "traced types: #{$traced_types}"
          signature_class = $traced_types[tp.defined_class]
          puts "signature class: #{signature_class}"
          next unless signature_class
          signature = signature_class[tp.method_id]
          puts "signature: #{signature}"
          next unless signature
          signature_arg_type = signature[arg].keys.first
          value.type = signature_arg_type
        end
      end
    end

    def types_hash
      @type_info_by_class
    end

    def types_json
      types_hash.to_json
    end

    private

    def format_type(type)
      type.klasses.map do |klass|
        { klass => type.klass_calls[klass].to_a }
      end
    end
  end

  describe PersonalGreeter, '#greet tested with arg_checking_instance_double' do
    let(:greeter) { arg_checking_instance_double(Greeter, greet: nil) }
    let(:personal_greeter) { PersonalGreeter.new('Dave', greeter) }

    it 'greets with a nil (default language)' do
      personal_greeter.greet
      expect(greeter.instance_double).to have_received(:greet).with('Dave', nil)
    end
  end

  describe PersonalGreeter, '#greet tested with traced signature double' do
    def auto_type_double(*args)
      AutoTypeDouble.new(*args)
    end

    let(:greeter) { auto_type_double(greet: nil) }

    # My next idea is to take the production type tracing code so that it could
    # infer a type for the :greeter double above based on the production type
    # trace.
    let(:personal_greeter) { PersonalGreeter.new('Dave', greeter) }

    it 'greets with a nil (default language)' do
      SpecTracer.new('/Users/dave/wmd/type_tracer/').start_trace
      personal_greeter.greet
      expect(greeter.wrapped_double).to have_received(:greet).with('Dave', nil)
    end
  end
end
