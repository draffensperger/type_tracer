$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'type_tracer'
require 'active_support'
require 'parser/current'
require 'rspec/mocks'

def arg_checking_instance_double(*args)
  ArgCheckedInstanceDouble.new(instance_double(*args))
end
