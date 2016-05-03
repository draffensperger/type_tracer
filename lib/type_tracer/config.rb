require 'singleton'

module TypeTracer
  class Config
    include Singleton

    attr_accessor :attribute_methods_definer, :type_sampler_root_path,
                  :type_sampler_path_regex, :git_commit, :sampled_types_url

    # Set this by giving a block to sample_types_for_requests
    attr_reader :rack_type_sample_decider

    def initialize
      @type_sampler_root_path = Dir.pwd
    end

    def sample_types_for_requests(&block)
      @rack_type_sample_decider = block.to_proc
    end
  end
end
