module MudPie
  COMMANDS = Hash.new do |hsh, name|
    Proc.new do
      if name
        raise "Unrecognized command: '#{name}'"
      else
        raise "No command specified."
      end
    end
  end
end

require 'mudpie/commands/stock'
require 'mudpie/commands/bake'
require 'mudpie/commands/compress'
require 'mudpie/commands/serve'
require 'mudpie/commands/s3_deploy'
require 'mudpie/commands/wp_import'
require 'mudpie/commands/help'
