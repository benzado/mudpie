module MudPie

  class Page

    attr_reader :pantry
    attr_reader :id
    attr_reader :mtime
    attr_reader :source_path
    attr_reader :url

    def initialize(pantry, row)
      raise ArgumentError unless row.is_a? Hash
      @pantry = pantry
      @id = row[:id]
      @mtime = Time.at(row[:mtime])
      @source_path = Pathname.new(row[:source_path])
      @url = row[:url]
    end

    def default_layout_name
      @source_path.extname.sub(/^\./, '_')
    end

    def meta
      @context ||= begin
        context = MudPie::PageContext.new(self)
        @pantry.load_meta_for_page_id(context, @id)
        context
      end
    end

    def each_layout
      if layout_name = meta[:layout]
        while layout_name
          layout = @pantry.layout_for_name(layout_name)
          raise "Can't find layout '#{layout_name}'" if layout.nil?
          yield layout
          layout_name = layout.meta[:layout]
        end
      elsif layout = @pantry.layout_for_name(default_layout_name)
        yield layout
      end
    end

    def meta_with_layout
      context = MudPie::PageContext.new(self)
      @pantry.load_meta_for_page_id(context, @id)
      each_layout do |layout|
        @pantry.load_meta_for_page_id(context, layout.id, true)
      end
      context
    end

    def http_content_type
      meta_with_layout[:http_content_type]
    end

    def static?
      Renderer.for_extname(@source_path.extname).nil?
    end

    def render_chain
      @render_chain ||= MudPie::build_render_chain(@source_path)
    end

    def layout_chain
      @layout_chain ||= begin
        chain = render_chain
        each_layout { |layout| chain = LayoutLink.new(layout, chain) }
        chain
      end
    end

    def render
      context = MudPie::PageContext.new(self)
      render_chain.render(context)
    end

    def render_with_layout
      context = MudPie::PageContext.new(self)
      layout_chain.render(context)
    end

    def render_to(target_path)
      raise "Use Pathname" unless target_path.is_a? Pathname
      target_path.dirname.mkpath
      if static?
        FileUtils.cp(@source_path, target_path, :preserve => true)
      else
        target_path.open('w') { |f| f.write self.render_with_layout }
      end
    end

  end

end
