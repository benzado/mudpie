class MudPie::Layout

  attr_reader :name

  def initialize(source_path)
    @name = File.basename(source_path).chomp(File.extname(source_path)).to_sym
    @renderer = MudPie::Renderer.for_extname(File.extname(source_path))
    raise "No renderer for layout #{@source_path}" unless @renderer
    @template = @renderer.load_template(source_path)
  end

  def render(b)
    @renderer.render_template(@template, b)
  end

end
