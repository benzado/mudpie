require 'pathname'
require 'mudpie/command'
require 'mudpie/pantry'

module MudPie::Command
  class Stock < BasicCommand
    def initialize_option_parser(opts)
      opts.banner = 'Stock a resource in pantry'
    end

    def execute
      MudPie::Pantry.new(config).stock
    end
  end
end
