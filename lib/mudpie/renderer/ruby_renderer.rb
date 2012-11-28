class MudPie::RubyRenderer < MudPie::Renderer

  register '.rb', self

  def read_meta(context, input)
    source = String.new
    for_each_line_matching(input, /^\s*@/) do |m|
      source << m.string
    end
    filename = input.path if input.respond_to?(:path)
    context.get_binding.eval(source, filename)
  end

  def render(context, input, output)
    tempout, $stdout = $stdout, output
    filename = input.path if input.respond_to? :path
    context.get_binding.eval(input.read, filename)
    $stdout = tempout
  end

  def load_template(path)
    [File.read(path), path]
  end

  def render_template(template, _binding)
    StringIO.open do |output|
      tempout, $stdout = $stdout, output
      _binding.eval *template
      $stdout = tempout
      output.string
    end
  end

end
