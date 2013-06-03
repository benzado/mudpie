require 'rack'
require 'rack/mudpie'

class MudPie::ServeCommand

  MudPie::COMMANDS['serve'] = self

  def self.summary
    "Start a local HTTP server"
  end

  def self.help
    "Usage: mudpie serve [hot|cold] [port]"
  end

  def self.call(argv, options)
    opts = Hash.new
    opts[:how] = argv[0].to_sym
    opts[:port] = argv[1].to_i if argv[1]
    self.new(MudPie::Bakery.new, opts).execute
  end

  def initialize(bakery, opts)
    @app = case opts[:how]
    when :cold then Rack::MudPie::cold_app(bakery)
    when :hot then Rack::MudPie::hot_app(bakery)
    else raise "Option :how required!"
    end
    @port = opts[:port] || 4742
  end

  def execute
    %w[INT TERM HUP].each do |signal|
      trap(signal) { Rack::Handler::WEBrick.shutdown }
    end
    puts "Point your browser to <http://localhost:#{@port}/>"
    Rack::Handler.default.run @app, :Port => @port
  end

end
