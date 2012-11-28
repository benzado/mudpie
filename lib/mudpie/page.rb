class MudPie::Page

  attr_reader :source_path, :mtime

  def initialize(bakery, source_path)
    @bakery = bakery
    @source_path = source_path
    @mtime = File.mtime(source_path)
    @renderers = MudPie::Renderer::for_path(@source_path)
  end

  def url
    MudPie::Renderer.strip_extensions(@source_path.sub(%r{^pages}, ''))
  end

  def static?
    @renderers.empty?
  end

  def meta
    context = MudPie::PageContext.new(@bakery, self)
    unless static?
      File.open(@source_path, 'r') { |f| @renderers.first.read_meta(context, f) }
    end
    return context
  end

  def render(context = nil)
    context = MudPie::PageContext.new(@bakery, self) if context.nil?
    input = File.open(@source_path, 'r')
    @renderers.each do |r|
      output = StringIO.new
      r.render(context, input, output)
      input.close
      input = output
      input.rewind
    end
    input.read
  end

  def render_to(target_path)
    if static?
      FileUtils.cp(@source_path, target_path, :preserve => true)
    else
      File.open(target_path, 'w') { |f| f.write self.render_with_layout }
    end
  end

  def render_with_layout
    context = MudPie::PageContext.new(@bakery, self)
    content = render(context)
    while context[:layout]
      layout = @bakery.layout_for_name(context[:layout])
      context[:layout] = nil
      b = context.get_binding { content }
      content = layout.render(b)
    end
    return content
  end

end
