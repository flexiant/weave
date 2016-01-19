module WeaveCookbook
  module WeaveHelpers
    def file_cache_path
      Chef::Config[:file_cache_path]
    end

    def weave_bin_prefix
      '/usr/local/bin'
    end

    def weave_etc_prefix
      '/etc/weave'
    end

    def weave_binary_name
      'weave'
    end

    def default_subnet
      '24'
    end

    def weave_cmd
      ::File.join(weave_bin_prefix, weave_binary_name)
    end

    def default_version
      'latest_release'
    end

    def default_source
      "https://github.com/weaveworks/weave/releases/download/#{version}/weave"
    end

    def weave_cmd_exists?
      return false unless ::File.exist?(weave_cmd)
      true
    end

  end
end
