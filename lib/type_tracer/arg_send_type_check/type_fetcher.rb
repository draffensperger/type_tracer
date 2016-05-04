# frozen_string_literal: true
require 'net/http'
require 'json'
require 'fileutils'

module TypeTracer
  class TypeFetcher
    class << self
      def fetch_sampled_types
        url = TypeTracer.config.sampled_types_url
        json = Net::HTTP.get(URI.parse(url))
        save_types_locally(json)
        JSON.parse(json).deep_symbolize_keys
      end

      def save_types_locally(types_json)
        root_path = TypeTracer.config.type_check_root_path
        folder = File.join(root_path, 'tmp', 'type_tracer')
        FileUtils.mkdir_p(folder)
        file = File.join(folder, 'sampled_types.json')
        File.write(file, types_json)
      end
    end
  end
end
