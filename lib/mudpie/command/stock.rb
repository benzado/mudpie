require 'pathname'
require 'mudpie/command'
require 'mudpie/pantry'
require 'mudpie/loader'

module MudPie::Command
  class Stock < BasicCommand
    def initialize_option_parser(opts)
      opts.banner = 'Stock a resource in pantry'
    end

    def execute
      @pantry = MudPie::Pantry.new(config)
      if path_args.empty?
        stock_path Pathname.new(config.path_to_source)
      else
        path_args.each do |arg|
          stock_path Pathname.new(arg)
        end
      end
    end

    def stock_path(path)
      if config.ignore_source_path?(path)
        logger.debug "Ignoring #{path}"
        return
      end
      if loader = MudPie::Loader.loader_for_path(path)
        logger.info "Stocking #{path}"
        @pantry.stock_resource_from_source(loader.load_resource, path)
      elsif path.directory?
        path.each_child { |p| stock_path(p) }
      else
        logger.fatal "No loader for path: #{path}"
      end
    end
  end
end
