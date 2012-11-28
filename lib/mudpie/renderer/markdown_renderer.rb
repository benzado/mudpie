require 'rdiscount'

class MudPie::MarkdownRenderer < MudPie::Renderer

  HEADER_PATTERN = /^[\-\+\*]\s+(\w+):\s*(.+)\s*$/

  register '.md', self

  def read_meta(context, input)
    for_each_line_matching(input, HEADER_PATTERN) do |m|
      key, value = m[1].to_sym, m[2]
      context[key] = parse_value(value)
    end
  end

  def render(context, input, output)
    source = for_each_line_matching(input, HEADER_PATTERN, String.new) do |m|
      key, value = m[1].to_sym, m[2]
      context[key] = parse_value(value)
    end
    r = RDiscount.new(source)
    r.smart = true
    output.write r.to_html
  end

  private

  BACKSLASH_SUBSTITUTIONS = {
    '\n' => "\n",
    '\t' => "\t",
    '\"' => '"'
  }

  def parse_value(text)
    case text
    when /^"(.*)"$/ then $1.gsub(/\\./) { |c| BACKSLASH_SUBSTITUTIONS[c] || c[1] }
    when /^[0-9]+$/ then text.to_i
    when /^\[(.*)\]$/ then $1.split(/\s*,\s*/)
    else text.to_s
    end
  end

end
