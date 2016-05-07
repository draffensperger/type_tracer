# frozen_string_literal: true
# rake tasks for Rails 3+
module TypeTracer
  class Railtie < ::Rails::Railtie
    rake_tasks do
      require 'type_tracer/rake/tasks'
    end

    initializer 'type_tracer.insert_middleware' do |app|
      require 'type_tracer/rack/type_sampler_middleware.rb'
      app.config.middleware.use 'TypeTracer::TypeSamplerMiddleware'
    end
  end
end
