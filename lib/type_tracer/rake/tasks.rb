desc 'Checks for undefined instance methods'
namespace :type_tracer do
  task check_method_calls: :environment do |_, _args|
    root_dir = Rails.root
    ruby_files = Dir.glob(root_dir.join('app/**/*.rb'))
    ruby_files.each { |file| load(file) }

    TypeTracer.config.attribute_methods_definer.try(:call)

    found_undefined_method = false
    stream = STDOUT

    ruby_files.each do |file|
      source = File.read(file)
      checker = TypeTracer::InstanceMethodChecker.new(source, file, stream)
      found_undefined_method = true if checker.check_instance_methods
    end

    exit(1) if found_undefined_method
  end
end