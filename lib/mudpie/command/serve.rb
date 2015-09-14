require 'rack'
require 'mudpie/command'
require 'mudpie/server'

module MudPie::Command
  class Serve < BasicCommand
    def initialize_option_parser(opts)
      opts.banner = 'Freshly baked pages, on demand'
      opts.on('--hot', 'bake pages on demand') do
        @mode = :hot
      end
      opts.on('--cold', 'serve already-baked pages') do
        @mode = :cold
      end
      opts.on('-p', '--port', OptionParser::DecimalInteger, 'port number to listen on') do |port|
        @port = port
      end
    end

    def mode
      @mode || :hot
    end

    def port
      @port || 4000
    end

    def hot_app
      Rack::Builder.app do
        use Rack::ShowExceptions
        use Rack::Lint
        run MudPie::Server.new
      end
    end

    def cold_app
      raise "serve --cold is not yet implemented"
    end

    def app
      if mode == :hot
        logger.info "Be careful, the plate is very hot!"
        hot_app
      else
        logger.info "Sweet and cold, coming right up!"
        cold_app
      end
    end

    def execute
      logger.info "Point your browser to <http://localhost:#{port}>"
      %w[INT TERM HUP].each do |signal|
        trap(signal) { Rack::Handler::WEBrick.shutdown }
      end
      Rack::Handler::WEBrick.run app, Port: port
    end
  end
end
