require 'webrick'

module MudPie

class Server < WEBrick::HTTPServer

  attr_reader :site

  def initialize(site, on_the_fly = true)
    @site = site
    super(:Port => @site.config['server_port'])
    if on_the_fly then
      mount '/', HotServlet
    else
      mount '/', WEBrick::HTTPServlet::FileHandler, @site.config['destination']
    end
    ['INT', 'TERM', 'HUP'].each { |name| trap(name) { shutdown } }
  end

end

class HotServlet < WEBrick::HTTPServlet::FileHandler

  def initialize(server)
    super(server, '.')
    @site = server.site
    @site.reload_layouts
    @site.update_index
  end

  def do_GET(request, response)
    path = request.path
    page = @site.index.page_for_url(path)
    page = @site.index.page_for_url(path + 'index.html') if page.nil?
    raise WEBrick::HTTPStatus::NotFound if page.nil?
    if page.ymf_len == 0 then
      super(request, response)
    else
      response.body = page.rendered_content
    end
  end

end

end # module
