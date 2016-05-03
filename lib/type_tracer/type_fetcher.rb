require 'net/http'
require 'fileutils'

module TypeTracer
  class TypeFetcher
    def initialize(sampled_types)
      @sampled_types = sampled_types
    end

    # def changed_files
    #   url = TypeTracer.config.sampled_types_url
    #   @sampled_types = JSON.parse(Net::HTTP.get(URI.parse(url))).deep_symbolize_keys
    # end

    def changed_files
      @changed_files ||= `git diff --name-only #{@sampled_types[:git_commit]} HEAD`
    end

    class << self
      def fetch_types
        root_path = TypeTracer.config.type_sampler_root_path
        folder = File.join(root_path, 'tmp', 'type_tracer')
        FileUtils.mkdir_p(folder)
        file = File.join(folder, 'sampled_types.json')
        url = TypeTracer.config.sampled_types_url

        File.write(file, Net::HTTP.get(URI.parse(url)))
      end
    end
  end
end
