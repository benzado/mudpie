require 'mudpie/layout/erb'

module MudPie::Renderer
  class ERB < BasicRenderer
    def rendered_content(context)
      context.content_type ||= 'text/html'
      erb = MudPie::Layout::ERB.new(resource)
      erb.render(context, nil)
    end
  end

  add_renderer_class 'erb', ERB
end
