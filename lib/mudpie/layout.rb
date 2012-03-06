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

  def render(content, page)
    puts "  Embedding in #{@path}"
    output = begin
      context = { 'site' => @site, 'page' => page, 'content' => content }
      template.render! context, { :filters => [MudPie::Filters] }
    rescue => e
      puts "Liquid Exception: #{e.message} in layout #{@path}"
      puts "  " + e.backtrace.join("\n  ")
    end
    if layout then
      layout.render output, page
    else
      output
    end
  end

end

end # module
