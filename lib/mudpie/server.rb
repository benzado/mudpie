require 'webrick'

module MudPie

  class Server < WEBrick::HTTPServer

    attr_reader :bakery

    def initialize(bakery)
      super(:Port => 3000)
      if bakery.serve_hot?
        mount '/', HotPieServlet, bakery
        puts "Some Like It Hot"
      else
        mount '/', WEBrick::HTTPServlet::FileHandler, Bakery::OUTPUT_ROOT
        puts "Some Like It Cold"
      end
      %w[INT TERM HUP].each { |name| trap(name) { shutdown } }
    end

  end

  class HotPieServlet < WEBrick::HTTPServlet::FileHandler

    def initialize(server, bakery)
      super(server, 'pages')
      @bakery = bakery
      @bakery.reload_layouts
    end

    def do_GET(request, response)
      response['X-Served-Hot-By'] = 'MudPie/' + MudPie::VERSION
      path = request.path
      page = if path[-1] == '/'
        @bakery.page_for_url(File.join(path, 'index.html'))
      else
        @bakery.page_for_url(path)
      end
      if page.nil? or page.static?
        super(request, response)
      else
        response.body = page.render_with_layout
      end
    end

  end

end
