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
      pantry.resources.each do |resource|
        logger.info resource.path
        logger.info "  Source: #{resource.source_path}"
        logger.info "    Last Modified: #{resource.source_modified_at}"
        logger.info "    Size: #{resource.source_length} bytes"
        logger.warn "    Needs Restocking" unless resource.up_to_date?
        logger.info "  Renderer: #{resource.renderer_name}"
        logger.info "  Metadata: #{resource.metadata.count} keys"
        logger.info "  Content: #{resource.content_length} bytes"
      end
    end
  end
end
