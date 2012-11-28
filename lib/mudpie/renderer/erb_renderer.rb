require 'erb'

class MudPie::ERBRenderer < MudPie::Renderer

  register '.erb', self

  def read_meta(context, input)
    source = String.new
    for_each_line_matching(input, /^%/) do |m|
      source << m.post_match
    end
    filename = input.path if input.respond_to?(:path)
    context.get_binding.eval(source, filename)
  end

  def render(context, input, output)
    t = ERB.new(input.read, nil, '%')
    t.filename = input.path if input.respond_to?(:path)
    output.write t.result(context.get_binding)
  end

  def load_template(path)
    t = ERB.new(File.read(path), nil, '%')
    t.filename = path
    return t
  end

  def render_template(template, _binding)
    template.result(_binding)
  end

end
