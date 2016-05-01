# rake tasks for Rails 3+
module TypeTracer
  class Railtie < ::Rails::Railtie
    rake_tasks do
      require 'type_tracer/rake/tasks'
    end
  end
end
