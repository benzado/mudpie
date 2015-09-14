module MudPie::Renderer
  class Default < BasicRenderer
    def rendered_content(context)
      resource.content
    end
  end

  add_renderer_class 'default', Default
end
