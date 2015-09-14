require 'mudpie/command'
require 'mudpie/pantry'

module MudPie::Command
  class Stock < BasicCommand
    def initialize_option_parser(opts)
      opts.banner = 'Stock a resource in pantry'
    end

    def execute
      if path_args.empty?
        logger.warn 'No files specified!'
      else
        pantry = MudPie::Pantry.new(config)
        path_args.each do |arg|
          logger.info "Stocking #{arg}"
          pantry.stock(Pathname.new(arg))
        end
      end
    end
  end
end
