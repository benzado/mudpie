require 'mudpie'
require 'mudpie/commands'
require 'rack'
require 'rack/mudpie'
require 'rake/clean'
require 'rake/tasklib'
require 'rake/sprocketstask'

module Rake
  class MudPieTask < TaskLib
  
    def initialize
      @db_path = MudPie::Pantry::DB_PATH
      @bakery = MudPie::Bakery.new
      yield self if block_given?
      define
    end
  
    def define
      CLEAN.include(@bakery.output_root)
      CLOBBER.include(@db_path)
      SprocketsTask.new do |t|
        t.environment = @bakery.sprockets_environment
        t.output      = File.join(@bakery.output_root, 'assets')
        t.assets      = @bakery.sprockets_assets
      end
      task :stock do
        MudPie::StockCommand.new.execute
      end
      desc "Render pages to `#{@bakery.output_root}`"
      task :bake => [:stock, :assets] do
        MudPie::BakeCommand.new.execute
      end
      desc "Compress files in `#{@bakery.output_root}`"
      task :compress do
        MudPie::CompressCommand.new(@bakery).execute
      end
      namespace :serve do
        %w[INT TERM HUP].each do |signal|
          trap(signal) { Rack::Handler::WEBrick.shutdown }
        end
        desc "Start static HTTP server in `#{@bakery.output_root}`"
        task :cold do
          Rack::Handler.default.run Rack::MudPie::cold_app(@bakery)
        end
        desc "Start dynamic HTTP server for live previews."
        task :hot do
          Rack::Handler.default.run Rack::MudPie::hot_app(@bakery)
        end
      end
    end

  end
end
