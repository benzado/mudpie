module MudPie

  def self.build_render_chain(source_path)
    url = source_path.to_s.sub(%r{^[^/]+}, '')
    chain = SourceLink.new(url, source_path)
    while r = Renderer.for_extname(File.extname(url))
      url = url.chomp(File.extname(url))
      chain = RenderLink.new(url, r, chain)
    end
    chain
  end

  class ChainLink

    def static?
      false
    end

    def meta
      context = PageContext.new(nil)
      read_meta(context)
      context
    end

    def render(context)
    end

  end

  class SourceLink < ChainLink

    attr_reader :url

    def initialize(url, path)
      @url = url
      @path = path
    end

    def static?
      true
    end

    def read_meta(context)
    end

    def open
      f = File.open(@path, 'r')
      yield f
    ensure
      f.close
    end

    def render(context)
      @path.read
    end

    def to_s
      "[SOURCE:#{@path}]"
    end

  end

  class RenderLink < ChainLink

    attr_reader :url

    def initialize(url, renderer, link)
      @url = url
      @renderer = renderer
      @link = link
    end

    def read_meta(context)
      @link.read_meta(context)
      if @link.respond_to?(:open)
        @link.open do |f|
          @renderer.read_meta(context, f)
        end
      end
    end

    def render(context)
      input = StringIO.new @link.render(context)
      output = StringIO.new
      @renderer.render(context, input, output)
      output.rewind
      output.read
    end

    def to_s
      "[RENDER:#{@renderer.class}:#{@link}]"
    end

  end

  class LayoutLink < ChainLink

    def initialize(layout, link)
      @layout = layout
      @link = link
      @renderer = MudPie::Renderer.for_extname(@layout.source_path.extname)
      raise "No renderer for layout #{@layout.source_path}" unless @renderer
      @template = @renderer.load_template(@layout.source_path.to_s)
    end

    def url
      @link.url
    end

    def render(context)
      content = @link.render(context)
      b = context.get_binding { content }
      @renderer.render_template(@template, b)
    end

    def to_s
      "[LAYOUT:#{@layout.url}:#{@link}]"
    end

  end

end
