require 'mudpie'
require 'mudpie/commands/stock'

module Rack::MudPie

  class PageServer

    HEADER_FOR_META_KEY = {
      http_content_type: 'Content-Type',
      http_cache_control: 'Cache-Control'
    }

    INDEX_NAME = 'index.html'

    def initialize(app, bakery)
      @app = app
      @bakery = bakery
      @bakery.serve_hot!
      @stock = MudPie::StockCommand.new(@bakery)
    end
    def call(env)
      request = Rack::Request.new(env)
      path = request.path
      if path[-1] == '/'
        path << INDEX_NAME
        puts "Appending '#{INDEX_NAME} to request."
      end
      page = @bakery.page_for_url(path)
      if page.nil? or page.static?
        env['PATH_INFO'] = path # in case we re-wrote it
        @app.call(env)
      else
        @stock.execute
        response = Rack::Response.new
        response['X-Served-Hot-By'] = "MudPie/#{MudPie::VERSION}"
        HEADER_FOR_META_KEY.each do |key, header|
          value = page.meta_with_layout[key]
          response[header] = value if value
        end
        if request.get?
          response.write page.render_with_layout
        end
        response.finish
      end
    end
  end

  def self.hot_app(bakery)
    Rack::Builder.app do
      use Rack::ShowExceptions
      map '/assets' do
        run bakery.sprockets_environment
      end
      use Rack::Lint
      use PageServer, bakery
      use Rack::Lint
      run Rack::File.new('pages')
    end
  end

  def self.cold_app(bakery)
    Rack::Static.new(nil, urls: [""], root: 'public', index: INDEX_NAME)
  end

end
