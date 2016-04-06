Dir[File.join(File.dirname(__FILE__), 'type_tracer', '*.rb')].each do |file|
  require File.join('type_tracer', File.basename(file, '.rb'))
end

module TypeTracer
  # Your code goes here...
end
