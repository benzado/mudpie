require 'mudpie'

module Rack::MudPie

  class PageServer
    def initialize(app, bakery)
      @app = app
      @bakery = bakery
      @bakery.serve_hot!
      @bakery.reload_layouts
    end
    def call(env)
      request = Rack::Request.new(env)
      path = request.path
      page = if path[-1] == '/'
        @bakery.page_for_url(path + 'index.html')
      else
        @bakery.page_for_url(path)
      end
      if page.nil? or page.static?
        @app.call(env)
      else
        response = Rack::Response.new
        response['X-Served-Hot-By'] = 'MudPie/' + MudPie::VERSION
        response.write page.render_with_layout
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
    Rack::Static.new(nil, :urls => [""], :root => 'public', :index => 'index.html')
  end

end
