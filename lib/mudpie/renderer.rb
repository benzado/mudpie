require 'mudpie/render_context'
require 'mudpie/layout'

module MudPie::Renderer
  RENDERER_FOR_NAME = Hash.new

  class UnsupportedRendererError < StandardError
    attr :renderer_name

    def initialize(renderer_name)
      @renderer_name = renderer_name
      super("Unsupported renderer '#{renderer_name}'")
    end
  end

  class BasicRenderer
    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

    def rendered_content(context)
      raise "rendered_content not implemented by #{self.class.name}"
    end

    def render_to(output, context = nil)
      context ||= MudPie::RenderContext.new
      # TODO: merge default metadata from config
      context.merge_metadata @resource.metadata
      result = rendered_content(context)
      while context.needs_layout?
        layout = MudPie::Layout.find_by_name(context.next_layout_name)
        result = layout.render(context, result)
      end
      output.write result
    end
  end

  def self.add_renderer_class(name, renderer_class)
    RENDERER_FOR_NAME[name] = renderer_class
  end

  def self.renderer_class_for_name(name)
    RENDERER_FOR_NAME[name] or raise UnsupportedRendererError, name
  end
end

require 'mudpie/renderer/default'
require 'mudpie/renderer/markdown'
# require 'mudpie/renderer/textile'
# require 'mudpie/renderer/erb'
# require 'mudpie/renderer/ruby'
# require 'mudpie/renderer/shell_script'
# require 'mudpie/renderer/wordpress'
