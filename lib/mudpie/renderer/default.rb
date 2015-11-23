module MudPie::Renderer
  class Default < BasicRenderer
    def content_type
      MudPie.config.content_type_for_extname(File.extname(resource.path))
    end

    def rendered_content(context)
      context.content_type = content_type
      resource.content
    end
  end

  add_renderer_class 'default', Default
end
