require 'type_tracer/config'
require 'type_tracer/version'
require 'type_tracer/parser'

module TypeTracer
  class << self
    def config
      @config ||= TypeTracer::Config.instance
      yield @config if block_given?
      @config
    end
  end
end

require 'type_tracer/rails/railtie' if defined? Rails::Railtie
