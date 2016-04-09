require 'spec_helper'

module TypeTracer
  describe Greeter, '#greet' do
    let(:stream) { instance_double(IO, puts: nil) }

    it 'says hello in English' do
      Greeter.new(stream).greet('Dave', 'English')

      expect(stream).to have_received(:puts).with('Hello Dave!')
    end

    it 'says hello in english (lower case)' do
      Greeter.new(stream).greet('Dave', 'english')

      expect(stream).to have_received(:puts).with('Hello Dave!')
    end

    it 'says hello in Spanish' do
      Greeter.new(stream).greet('Dave', 'Spanish')

      expect(stream).to have_received(:puts).with('Hola Dave!')
    end
  end
end
