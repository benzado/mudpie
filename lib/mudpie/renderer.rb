class MudPie::Renderer

  RENDERERS = {}

  def self.register(extname, renderer_class)
    RENDERERS[extname] = renderer_class.new
  end

  def self.for_extname(extname)
    RENDERERS[extname]
  end

  def self.for_path(path)
    sequence = Array.new
    loop do
      extname = File.extname(path)
      if r = RENDERERS[extname]
        sequence << r
      else
        break
      end
      path = path.chomp(extname)
    end
    return sequence
  end

  def self.strip_extensions(path)
    new_path = path.dup
    loop do
      extname = File.extname(new_path)
      break unless RENDERERS[extname]
      new_path.chomp! extname
    end
    return new_path
  end

  # Abstract methods

  def read_meta(context, input)
    raise "Abstract method not implemented by #{self.class.name}"
  end

  def render(context, input, output)
    raise "Abstract method not implemented by #{self.class.name}"
  end

  def load_template(path)
    path
  end

  def render_template(template, _binding)
    raise "Abstract method not implemented by #{self.class.name}"
  end

  protected

  def for_each_line_matching(input, pattern, rest = nil)
    while line = input.gets do
      if m = pattern.match(line)
        yield m if block_given?
      else
        rest << line if rest
        break
      end
    end
    rest << input.read if rest
  end

end
