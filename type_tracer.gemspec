# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'type_tracer/version'

Gem::Specification.new do |spec|
  spec.name          = 'type_tracer'
  spec.version       = TypeTracer::VERSION
  spec.authors       = ['draffensperger']
  spec.email         = ['d.raffensperger@gmail.com']

  spec.summary       = 'Proof of concept tool for Ruby static/dynamic analysis'
  spec.description   = 'Proof of concept tool for Ruby static/dynamic analysis'
  spec.homepage      = "https://github.com/draffensperger/type_tracer"
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0")
                                        .reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency('parser', '>= 2.3.0.6', '< 3.0')
  spec.add_runtime_dependency('activesupport', '~> 4.2.6')
  spec.add_runtime_dependency('rubocop', '~> 0.39')

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry-byebug'
end
