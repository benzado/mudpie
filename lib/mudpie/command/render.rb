require 'optparse'
require 'pathname'
require 'mudpie/command'
require 'mudpie/configuration'
require 'mudpie/logger'
require 'mudpie/pantry'
require 'mudpie/renderer'

module MudPie::Command
  class Render < BasicCommand
    def initialize_option_parser(opts)
      opts.banner = 'Render a resource'
    end

    def execute
      pantry = MudPie::Pantry.new(config)
      path_args.each do |path|
        resource = pantry.resource_for_path(path)
        begin
          if resource
            resource.renderer.render_to($stdout)
          else
            logger.warn "#{path}: resource not found"
          end
        rescue => e
          logger.warn "#{path}: #{e.message}"
          logger.debug e.backtrace.join("\n")
        end
      end
    end
  end
end
