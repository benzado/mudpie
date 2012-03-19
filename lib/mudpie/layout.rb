module MudPie

class Layout < SourceFile

  def initialize(site, name)
    raise "Layout name must not be nil" if name.nil?
    @site = site
    super(File.join(@site.config['layouts_root'], name + '.html'))
  end

  def template
    @template ||= Liquid::Template.parse raw_content
  end

  def render(context)
    @site.add_dependency(@path)
    puts "  Embedding in #{@path}"
    content = begin
      template.render! context, { :filters => [MudPie::Filters] }
    rescue => e
      puts "Liquid Exception: #{e.message} in layout #{@path}"
      puts "  " + e.backtrace.join("\n  ")
    end
    if layout then
      layout.render context.merge('content' => content)
    else
      content
    end
  end

end

end # module
