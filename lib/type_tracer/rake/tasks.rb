# frozen_string_literal: true
require 'type_tracer/instance_method_checker'
require 'type_tracer/arg_send_type_check_runner'

desc 'Checks for undefined instance methods'
namespace :type_tracer do
  task check_method_calls: :environment do |_, _args|
    root_dir = defined?(Rails) ? Rails.root : '.'
    ruby_files = Dir.glob(root_dir.join('app/**/*.rb'))
    ruby_files.each { |file| load(file) }

    TypeTracer.config.attribute_methods_definer.try(:call)
    stream = STDOUT

    found_undefined_method = false

    ruby_files.each do |file|
      source = File.read(file)
      checker = TypeTracer::InstanceMethodChecker.new(source, file, stream)
      found_undefined_method = true if checker.check_instance_methods
    end
    exit(1) if found_undefined_method
  end

  task check_arg_sends: :environment do |_, _args|
    root_dir = TypeTracer.config.type_check_root_path.to_s + '/'
    files = Dir.glob(File.join(root_dir, '**/*.rb'))
    TypeTracer.config.type_check_path_regex = %r{\A(app|lib)/}
    type_check_files = files.select do |file|
      project_path = file[root_dir.size..-1]
      project_path =~ TypeTracer.config.type_check_path_regex
    end

    type_check_files.each { |file| load(file) }
    stream = STDOUT

    if TypeTracer::ArgSendTypeCheckRunner.new(type_check_files, stream).check_args
      exit(1)
    end
  end
end
