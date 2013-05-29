class MudPie::HelpCommand

  MudPie::COMMANDS['help'] = self

  def self.summary
    "Display help for a specific command"
  end

  def self.help
    "Usage: mudpie help <command-name>"
  end

  def self.call(argv, options)
    if argv.empty?
      puts help
    else
      puts MudPie::COMMANDS[argv[0]].help
    end
  end

end
