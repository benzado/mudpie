require 'mudpie/pantry'
require 'mudpie/execution_context'

module MudPie
  class Server
    def initialize
      @pantry = Pantry.new
    end

    def call(env)
      request = Rack::Request.new(env)
      path = request.path
      if path[-1] == '/'
        MudPie.logger.info "appending #{MudPie.config.index_name} to request for #{path}"
        path << MudPie.config.index_name
      end
      @pantry.stock
      response = Rack::Response.new
      resource = @pantry.resource_for_path(path)
      if resource.nil?
        response['Content-Type'] = 'text/plain'
        response.status = 404
        response.write "MudPie says: no known resource at #{path}.\r\n"
      else
        response['X-Served-Hot-By'] = "MudPie/#{MudPie::VERSION}"
        if request.get?
          context = RenderContext.new(@pantry)
          context.metadata[ExecutionContext::SERVED_HOT_KEY] = true
          resource.renderer.render_to(response, context)
          response['Content-Type'] = context.content_type!
        end
      end
      response.finish
    end
  end
end
