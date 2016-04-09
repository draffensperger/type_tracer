require 'spec_helper'

module TypeTracer
  describe PersonalGreeter, '#greet' do
    let(:greeter) { arg_checking_instance_double(Greeter, greet: nil) }
    let(:personal_greeter) { PersonalGreeter.new('Dave', greeter) }

    it 'greets with a nil (default language)' do
      personal_greeter.greet
      expect(greeter.instance_double).to have_received(:greet).with('Dave', nil)
    end
  end
end
