require 'type_tracer/type_sampler'

module TypeTracer
  class TypeSamplerMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      sample_decider = TypeTracer.config.rack_type_sample_decider
      TypeSampler.start if sample_decider && sample_decider.call(env)
      @app.call(env)
    ensure
      TypeSampler.stop
    end
  end
end
