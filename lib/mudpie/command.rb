module MudPie

HELP_TEXT = <<END_HELP_TEXT
MudPie v#{VERSION}

Usage:

  mudpie <command> [<config-path>]

Commands:

  bake - compiles site content into the output directory
  clean - deletes the index database and output directory
  serve hot - starts a local webserver that builds pages on demand
  serve cold - starts a local webserver pointed at the output directory
  compress - creates gzipped versions of compressable files
  help - prints this help text

END_HELP_TEXT

class Command

  def initialize(argv)
    @command = argv.shift || 'help'
    @argv = argv
  end

  def run
    m = begin
      s = "do_" + @command
      self.method(s.to_sym)
    rescue NameError
      puts "Unknown command '#{@command}'."
    end
    m.call unless m.nil?
  end

  def do_help
    puts HELP_TEXT
  end

  def do_clean
    path = @argv.shift || '.'
    @config = Config.new(path)
    index_path = @config['index_path']
    if File.exists? index_path then
      puts "Deleting #{index_path}"
      FileUtils.rm index_path
    end
    output_path = @config['destination']
    if File.exists? output_path then
      puts "Deleting #{output_path}"
      FileUtils.rm_r output_path
    end
  end

  def do_bake
    path = @argv.shift || '.'
    config = Config.new(path)
    site = Site.new(config)
    puts '##########################################'
    puts '# UPDATING INDEX #########################'
    puts '##########################################'
    site.update_index
    puts '##########################################'
    puts '# WRITING FILES ##########################'
    puts '##########################################'
    site.render_all
  end

  def do_serve
    temperature = @argv.shift || 'hot'
    path = @argv.shift || '.'
    config = Config.new(path, 'served' => temperature)
    site = Site.new(config)
    server = Server.new(site, temperature == 'hot')
    server.start
  end

  def do_compress
    path = @argv.shift || '.'
    config = Config.new(path)
    compressor = Compressor.new(config)
    compressor.compress_all
  end

end

end # module
