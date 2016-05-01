# Include files in the type_tracer subdirectory, but not in recursive
# subdirectories
Dir[File.join(File.dirname(__FILE__), 'type_tracer', '*.rb')].each do |file|
  next if file =~ /version/
  require File.join('type_tracer', File.basename(file, '.rb'))
end

require 'type_tracer/rails/railtie' if defined? Rails::Railtie

module TypeTracer
  class << self
    def config
      @config ||= TypeTracer::Config.instance
      yield @config if block_given?
      @config
    end
  end
end
