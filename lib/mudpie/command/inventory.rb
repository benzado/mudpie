require 'optparse'
require 'pathname'
require 'mudpie/command'
require 'mudpie/pantry'

module MudPie::Command
  class Inventory < BasicCommand
    def initialize_option_parser(opts)
      opts.banner = 'Inventory'
    end

    def execute
      pantry = MudPie::Pantry.new(config)
      pantry.each_resource do |resource|
        logger.info resource.path
        logger.info "  Stocked: #{resource.stocked_at}"
        logger.info "  Last Modified: #{resource.modified_at}"
        logger.info "  Renderer: #{resource.renderer_name}"
        logger.info "  Metadata: #{resource.metadata.count} keys"
        logger.info "  Content: #{resource.content_length} bytes"
      end
    end
  end
end
