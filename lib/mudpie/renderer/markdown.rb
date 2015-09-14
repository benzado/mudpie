require 'kramdown'

module MudPie::Renderer
  class Markdown < BasicRenderer
    def rendered_content(context)
      Kramdown::Document.new(resource.content).to_html
    end
  end

  add_renderer_class 'markdown', Markdown
end